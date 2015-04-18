//
//  KDERemoteConfiguration_TestCase.swift
//  KDEConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit
import XCTest
import KDEConfigurationKit

class KDERemoteConfiguration_TestCase: XCTestCase {
    func testInitialDownload() {
        let URL = NSURL(string: "https://raw.githubusercontent.com/delannoyk/KDEConfigurationKit/master/SampleConfig.json")!

        let URLBuilder = KDESimpleURLBuilder(URL: URL)
        let configuration = KDERemoteConfiguration(URLBuilder: URLBuilder, parser: KDERemoteConfigurationFlatJSONParser(), cache: KDERemoteConfigurationCache(identifier: "123", encryptor: nil))

        let expectation = self.expectationWithDescription("Waiting for cycle completed notification")

        let observer = NSNotificationCenter.defaultCenter().addObserverForName(KDERemoteConfigurationDidEndCycleNotification, object: nil, queue: nil) { (note) -> Void in
            XCTAssert(configuration["Foo1"] == "Bar1", "Configuration[Foo1] should be equal to Bar1")
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(10, handler: { (error) -> Void in

        })
    }
}
