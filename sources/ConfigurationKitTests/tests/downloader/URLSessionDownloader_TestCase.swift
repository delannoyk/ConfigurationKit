//
//  URLSessionDownloader_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 25/07/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

class DataTask: URLSessionDataTask {
    var completion: ((Data?, URLResponse?, Error?) -> Void)?
    var call = true

    override func resume() {
        if call { completion?(nil, nil, nil) }
    }

    override func cancel() {
    }
}

class FakeURLSession: URLSession {
    var call = true

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let d = DataTask()
        d.completion = completionHandler
        d.call = call
        return d
    }
}

class URLSessionDownloader_TestCase: XCTestCase {
    let urlSession = FakeURLSession()

    func testCompletionGetsCalled() {
        let e = expectation(description: "Wait for download data completion")
        let downloader = URLSessionDownloader(session: urlSession,
            responseQueue: .global())

        urlSession.call = true

        downloader.downloadData(with: URLRequest(url: URL(string: "http://google.com")!)) { data, error in
            e.fulfill()
        }

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }

    func testHasPendingRequestIsTrue() {
        let downloader = URLSessionDownloader(session: urlSession,
            responseQueue: .global())

        urlSession.call = false

        downloader.downloadData(with: URLRequest(url: URL(string: "http://google.com")!)) { data, error in
            XCTFail()
        }
        XCTAssert(downloader.hasPendingRequest)
    }

    func testNewDownloadCancelPreviousOne() {
        let downloader = URLSessionDownloader(session: urlSession,
            responseQueue: .global())

        urlSession.call = false

        downloader.downloadData(with: URLRequest(url: URL(string: "http://google.com")!)) { data, error in
            XCTFail()
        }

        urlSession.call = true

        let e = expectation(description: "Wait for download data completion")
        downloader.downloadData(with: URLRequest(url: URL(string: "http://google.com")!)) { data, error in
            XCTAssertNil(error)
            e.fulfill()
        }

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
}
