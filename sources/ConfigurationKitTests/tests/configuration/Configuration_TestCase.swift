//
//  Configuration_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 22/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

class Configuration_TestCase: XCTestCase {
    class E: EventProducer {
        var started = false
        weak var eventListener: EventListener?

        func startProducingEvents() {
            started = true
        }
        func stopProducingEvents() {
            started = false
        }
    }

    class FakeDownloader: Downloader {
        var hasPendingRequest = false

        var onDownload: ((URLRequest, (Data?, Error?) -> Void) -> Void)?

        func downloadData(with request: URLRequest, completion: @escaping (Data?, Error?) -> Void) {
            hasPendingRequest = true
            onDownload?(request) { [weak self] in
                self?.hasPendingRequest = false
                completion($0, $1)
            }
        }
    }

    class FakeCacher: Cacher {
        var cache = [String: Data]()

        func store(_ data: Data, at key: String) throws {
            cache[key] = data
        }

        func remove(at key: String) {
            cache.removeValue(forKey: key)
        }

        func data(at key: String) -> Data? {
            return cache[key]
        }

        func hasData(at key: String) -> Bool {
            return cache[key] != nil
        }
    }

    class Delegate: ConfigurationDelegate {
        var onChange: ((Change<String, String>) -> Void)?
        var onEnd: ((Error?) -> Void)?
        var onBegin: ((Void) -> Void)?

        func configuration(_ configuration: Configuration, didDetectChange change: Change<String, String>) {
            onChange?(change)
        }

        func configuration(_ configuration: Configuration, didEndCycleWithError error: Error?) {
            onEnd?(error)
        }

        func configurationWillBeginCycle(_ configuration: Configuration) {
            onBegin?()
        }
    }


    let download: Configuration.DownloadInitializer = (SimpleURLRequestBuilder(url: URL(string: "http://google.com")!), FlatJSONParser(), nil)

    func testConfigurationStartsEventProducersAndSetDelegate() {
        let eventProducer = E()

        let configuration = Configuration(downloadInitializer: download,
            cycleGenerators: [eventProducer],
            initialConfiguration: [:])
        XCTAssert(eventProducer.started)
        XCTAssertNotNil(eventProducer.eventListener)
        XCTAssertNotNil(configuration.configurationDate)
    }

    func testConfigurationHasInitialKeys() {
        let configuration = Configuration(downloadInitializer: download,
            cycleGenerators: [E()],
            initialConfiguration: ["a":"b"])
        XCTAssertNotNil(configuration["a"])
        XCTAssertEqual(configuration["a"], "b")
    }

    func testConfigurationHasInitialKeysWhenUsingCacher() {
        let path = URL(fileURLWithPath: "configuration").path
        let fileContent = "{\"a\": \"0\", \"b\": \"1\"}"
        let date = Date(timeIntervalSince1970: 0)

        let fileManager = FakeManager()
        fileManager.onData = { url in
            if url.path == path {
                return fileContent.data(using: .utf8)
            }
            return nil
        }
        fileManager.onAttributes = { path in
            return [.modificationDate: date]
        }

        let configuration = Configuration(downloadInitializer: download,
            cacheInitializer: nil,
            cycleGenerators: [],
            newEventCancelCurrentOne: false,
            initialConfigurationFilePath: path,
            fileManager: fileManager)
        XCTAssertNotNil(configuration["a"])
        XCTAssertEqual(configuration["a"], "0")
        XCTAssertNotNil(configuration["b"])
        XCTAssertEqual(configuration["b"], "1")
        XCTAssertEqual(configuration.configurationDate, date)
    }

    func testConfigurationFailsToLoadIfFileDoesntExist() {
        let path = NSURL(fileURLWithPath: "configuration").path!

        let fileManager = FakeManager()
        fileManager.onData = { url in
            return nil
        }
        fileManager.onAttributes = { path in
            return [:]
        }

        let configuration = Configuration(downloadInitializer: download,
            cacheInitializer: nil,
            cycleGenerators: [],
            newEventCancelCurrentOne: false,
            initialConfigurationFilePath: path,
            fileManager: fileManager)
        XCTAssertNil(configuration["a"])
        XCTAssertNil(configuration["b"])
    }

    func testCycleBeginsWhenProducingAnEvent() {
        let eventProducer = E()

        let configuration = Configuration(downloadInitializer: download,
            cycleGenerators: [eventProducer],
            initialConfiguration: [:])

        let delegate = Delegate()
        configuration.registerDelegate(delegate)
        configuration.downloader = FakeDownloader()

        let e = expectation(description: "Waiting for delegate to get called")
        delegate.onBegin = {
            e.fulfill()
        }
        eventProducer.eventListener?.onEvent()

        waitForExpectations(timeout: 1) { error in
            configuration.unregisterDelegate(delegate)
            XCTAssertEqual(configuration.delegates.count, 0)

            if let _ = error {
                XCTFail()
            }
        }
    }

    func testConfigurationFireChangeWhenCycleEndsWithAValueChanged() {
        let eventProducer = E()
        let downloader = FakeDownloader()

        let configuration = Configuration(downloadInitializer: download,
            cycleGenerators: [eventProducer],
            initialConfiguration: ["a":"0"])
        configuration.downloader = downloader

        downloader.onDownload = { request, completion in
            completion("{\"a\": \"1\"}".data(using: .utf8), nil)
        }

        let delegate = Delegate()
        configuration.registerDelegate(delegate)

        let e = expectation(description: "Waiting for delegate to get called")
        delegate.onChange = { change in
            XCTAssert(change.isChange)
            XCTAssertEqual(change.key, "a")
            XCTAssertEqual(change.oldValue, "0")
            XCTAssertEqual(change.newValue, "1")
            e.fulfill()
        }

        eventProducer.eventListener?.onEvent()

        waitForExpectations(timeout: 1) { error in
            if let _ = error {
                XCTFail()
            }
        }
    }

    func testConfigurationFireDeleteWhenCycleEndsWithAKeyRemoved() {
        let eventProducer = E()
        let downloader = FakeDownloader()

        let configuration = Configuration(downloadInitializer: download,
            cycleGenerators: [eventProducer],
            initialConfiguration: ["a":"0"])
        configuration.downloader = downloader

        downloader.onDownload = { request, completion in
            completion("{}".data(using: .utf8), nil)
        }

        let delegate = Delegate()
        configuration.registerDelegate(delegate)

        let e = expectation(description: "Waiting for delegate to get called")
        delegate.onChange = { change in
            XCTAssert(change.isRemoval)
            XCTAssertEqual(change.key, "a")
            XCTAssertEqual(change.oldValue, "0")
            XCTAssertNil(change.newValue)
            e.fulfill()
        }

        eventProducer.eventListener?.onEvent()

        waitForExpectations(timeout: 1) { error in
            if let _ = error {
                XCTFail()
            }
        }
    }

    func testConfigurationFireDeleteWhenCycleEndsWithAKeyAdded() {
        let eventProducer = E()
        let downloader = FakeDownloader()

        let configuration = Configuration(downloadInitializer: download,
            cycleGenerators: [eventProducer],
            initialConfiguration: ["a":"0"])
        configuration.downloader = downloader

        downloader.onDownload = { request, completion in
            completion("{\"a\": \"0\", \"b\": \"1\"}".data(using: .utf8), nil)
        }

        let delegate = Delegate()
        configuration.registerDelegate(delegate)

        let e = expectation(description: "Waiting for delegate to get called")
        delegate.onChange = { change in
            XCTAssert(change.isAddition)
            XCTAssertEqual(change.key, "b")
            XCTAssertNil(change.oldValue)
            XCTAssertEqual(change.newValue, "1")
            e.fulfill()
        }

        eventProducer.eventListener?.onEvent()

        waitForExpectations(timeout: 1) { error in
            if let _ = error {
                XCTFail()
            }
        }
    }

    func testConfigurationInitialConfigurationWithCacher() {
        let cacher = FakeCacher()
        cacher.cache["configuration"] = NSKeyedArchiver.archivedData(withRootObject: ["a":"1", "b":"2"])
        cacher.cache["date"] = NSKeyedArchiver.archivedData(withRootObject: Date())

        let configuration = Configuration(downloadInitializer: download,
            cacheInitializer: (cacher, nil),
            cycleGenerators: [],
            newEventCancelCurrentOne: true,
            initialConfiguration: [:])
        XCTAssertEqual(configuration["a"], "1")
        XCTAssertEqual(configuration["b"], "2")
    }
}
