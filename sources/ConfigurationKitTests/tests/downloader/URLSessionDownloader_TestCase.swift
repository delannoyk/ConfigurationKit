//
//  URLSessionDownloader_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 25/07/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

class DataTask: NSURLSessionDataTask {
    var completion: ((NSData?, NSURLResponse?, NSError?) -> Void)?
    var call = true

    override func resume() {
        if call { completion?(nil, nil, nil) }
    }

    override func cancel() {
    }
}

class URLSession: NSURLSession {
    var call = true

    override func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
        let d = DataTask()
        d.completion = completionHandler
        d.call = call
        return d
    }
}

class URLSessionDownloader_TestCase: XCTestCase {
    let urlSession = URLSession()

    func testCompletionGetsCalled() {
        let expectation = expectationWithDescription("Wait for download data completion")
        let downloader = URLSessionDownloader(session: urlSession,
            responseQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

        urlSession.call = true

        downloader.downloadData(NSURLRequest()) { data, error in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1) { error in
            XCTAssertNil(error)
        }
    }

    func testHasPendingRequestIsTrue() {
        let downloader = URLSessionDownloader(session: urlSession,
            responseQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

        urlSession.call = false

        downloader.downloadData(NSURLRequest()) { data, error in
            XCTFail()
        }
        XCTAssert(downloader.hasPendingRequest)
    }

    func testNewDownloadCancelPreviousOne() {
        let downloader = URLSessionDownloader(session: urlSession,
            responseQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

        urlSession.call = false

        downloader.downloadData(NSURLRequest()) { data, error in
            XCTFail()
        }

        urlSession.call = true

        let expectation = expectationWithDescription("Wait for download data completion")
        downloader.downloadData(NSURLRequest()) { data, error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1) { error in
            XCTAssertNil(error)
        }
    }
}
