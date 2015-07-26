//
//  FileDownloader_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 25/07/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import XCTest
import ConfigurationKit
import UIKit

class FileDownloader_TestCase: XCTestCase {
    //Testing auto-refresh
    func testAutoRefreshEnabled() {
        let onBegin = { () -> NSURLRequest? in
            let bundle = NSBundle(forClass: FileDownloader_TestCase.self)
            if let URL = bundle.URLForResource("SampleConfig", withExtension: "plist") {
                return NSURLRequest(URL: URL)
            }
            return nil
        }

        let fileDownloader = FileDownloader(refreshWhenEnteringForeground: true,
            refreshOnIntervalBasis: true,
            refreshInterval: 5,
            beginBlock: onBegin)

        let expectation = expectationWithDescription("Waiting for refresh")
        let time = NSDate()
        var refreshCount = 0

        fileDownloader.onRefreshComplete = { (data, response, error) -> Void in
            //The first refresh comes from the .start()
            if refreshCount == 0 {
                refreshCount++
                return
            }

            fileDownloader.stop()
            let refreshTime = NSDate().timeIntervalSinceDate(time)
            XCTAssert(refreshTime >= 5 && refreshTime < 6, "We should refresh only after the timer fired")
            expectation.fulfill()
        }
        fileDownloader.start()

        waitForExpectationsWithTimeout(10, handler: { (error) -> Void in
        })
    }

    func testAutoRefreshDisabled() {
        let onBegin = { () -> NSURLRequest? in
            let bundle = NSBundle(forClass: FileDownloader_TestCase.self)
            if let URL = bundle.URLForResource("SampleConfig", withExtension: "plist") {
                return NSURLRequest(URL: URL)
            }
            return nil
        }

        let fileDownloader = FileDownloader(refreshWhenEnteringForeground: true,
            refreshOnIntervalBasis: false,
            refreshInterval: 1,
            beginBlock: onBegin)

        let expectation = expectationWithDescription("Waiting for refresh")
        var refreshCount = 0

        fileDownloader.onRefreshComplete = { (data, response, error) -> Void in
            //The first refresh comes from the .start()
            if refreshCount == 0 {
                refreshCount++
                return
            }

            XCTFail("We should be refreshing. Ever.")
        }
        fileDownloader.start()


        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(15, handler: { (error) -> Void in
        })
    }

    //Testing refreshing when entering foreground
    func testAutoRefreshOnForegroundEnabled() {
        let onBegin = { () -> NSURLRequest? in
            let bundle = NSBundle(forClass: FileDownloader_TestCase.self)
            if let URL = bundle.URLForResource("SampleConfig", withExtension: "plist") {
                return NSURLRequest(URL: URL)
            }
            return nil
        }

        let fileDownloader = FileDownloader(refreshWhenEnteringForeground: true,
            refreshOnIntervalBasis: false,
            refreshInterval: 1,
            beginBlock: onBegin)

        let expectation = expectationWithDescription("Waiting for refresh")
        var refreshCount = 0

        fileDownloader.onRefreshComplete = { (data, response, error) -> Void in
            //The first refresh comes from the .start()
            if refreshCount == 0 {
                refreshCount++
                return
            }

            refreshCount++
            expectation.fulfill()
        }
        fileDownloader.start()

        var date: NSDate?
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            date = NSDate()
            NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationWillEnterForegroundNotification, object: nil)
        }

        waitForExpectationsWithTimeout(10, handler: { (error) -> Void in
            fileDownloader.stop()

            XCTAssert(refreshCount == 2, "We should have refreshed twice (.start() + foreground)")
            XCTAssert(NSDate().timeIntervalSinceDate(date!) < 1, "The refresh should have happened in less than a sec")
        })
    }
}
