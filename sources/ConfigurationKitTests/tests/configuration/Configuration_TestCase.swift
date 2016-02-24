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

        var onDownload: ((NSURLRequest, (NSData?, ErrorType?) -> Void) -> Void)?
        func downloadData(request: NSURLRequest, completion: (NSData?, ErrorType?) -> Void) {
            hasPendingRequest = true
            onDownload?(request) { [weak self] in
                self?.hasPendingRequest = false
                completion($0, $1)
            }
        }
    }

    class Delegate: ConfigurationDelegate {
        var onChange: (Change<String, String> -> Void)?
        var onEnd: (ErrorType? -> Void)?
        var onBegin: (Void -> Void)?

        func configuration(configuration: Configuration, didDetectChange change: Change<String, String>) {
            onChange?(change)
        }

        func configuration(configuration: Configuration, didEndCycleWithError error: ErrorType?) {
            onEnd?(error)
        }

        func configurationWillBeginCycle(configuration: Configuration) {
            onBegin?()
        }
    }


    let download: Configuration.DownloadInitializer = (SimpleURLBuilder(URL: NSURL()), FlatJSONParser(), nil)

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

    func testCycleBeginsWhenProducingAnEvent() {
        let eventProducer = E()

        let configuration = Configuration(downloadInitializer: download,
            cycleGenerators: [eventProducer],
            initialConfiguration: [:])

        let delegate = Delegate()
        configuration.registerDelegate(delegate)
        configuration.downloader = FakeDownloader()

        let expectation = expectationWithDescription("Waiting for delegate to get called")
        delegate.onBegin = {
            expectation.fulfill()
        }
        eventProducer.eventListener?.onEvent()

        waitForExpectationsWithTimeout(1) { error in
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
            completion("{\"a\": \"1\"}".dataUsingEncoding(NSUTF8StringEncoding), nil)
        }

        let delegate = Delegate()
        configuration.registerDelegate(delegate)

        let expectation = expectationWithDescription("Waiting for delegate to get called")
        delegate.onChange = { change in
            XCTAssert(change.isChange)
            XCTAssertEqual(change.key, "a")
            XCTAssertEqual(change.oldValue, "0")
            XCTAssertEqual(change.newValue, "1")
            expectation.fulfill()
        }

        eventProducer.eventListener?.onEvent()

        waitForExpectationsWithTimeout(1) { error in
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
            completion("{}".dataUsingEncoding(NSUTF8StringEncoding), nil)
        }

        let delegate = Delegate()
        configuration.registerDelegate(delegate)

        let expectation = expectationWithDescription("Waiting for delegate to get called")
        delegate.onChange = { change in
            XCTAssert(change.isRemoval)
            XCTAssertEqual(change.key, "a")
            XCTAssertEqual(change.oldValue, "0")
            XCTAssertNil(change.newValue)
            expectation.fulfill()
        }

        eventProducer.eventListener?.onEvent()

        waitForExpectationsWithTimeout(1) { error in
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
            completion("{\"a\": \"0\", \"b\": \"1\"}".dataUsingEncoding(NSUTF8StringEncoding), nil)
        }

        let delegate = Delegate()
        configuration.registerDelegate(delegate)

        let expectation = expectationWithDescription("Waiting for delegate to get called")
        delegate.onChange = { change in
            XCTAssert(change.isAddition)
            XCTAssertEqual(change.key, "b")
            XCTAssertNil(change.oldValue)
            XCTAssertEqual(change.newValue, "1")
            expectation.fulfill()
        }

        eventProducer.eventListener?.onEvent()

        waitForExpectationsWithTimeout(1) { error in
            if let _ = error {
                XCTFail()
            }
        }
    }
}
