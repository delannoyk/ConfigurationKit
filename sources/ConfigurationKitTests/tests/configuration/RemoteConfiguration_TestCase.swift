//
//  RemoteConfiguration_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit
import XCTest
import ConfigurationKit

class RemoteConfiguration_TestCase: XCTestCase {
    func testInitialDownload() {
        let URL = NSURL(string: "https://raw.githubusercontent.com/delannoyk/KDEConfigurationKit/master/SampleConfig.json")!

        let URLBuilder = SimpleURLBuilder(URL: URL)
        let configuration = RemoteConfiguration(builder: URLBuilder, parser: RemoteConfigurationFlatJSONParser(), cache: RemoteConfigurationCache(identifier: "123", encryptor: nil))

        let expectation = self.expectationWithDescription("Waiting for cycle completed notification")

        let observer = NSNotificationCenter.defaultCenter().addObserverForName(RemoteConfigurationDidEndCycleNotification, object: nil, queue: nil) { (note) -> Void in
            XCTAssert(configuration["Foo1"] == "Bar1", "Configuration[Foo1] should be equal to Bar1")
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(10, handler: { (error) -> Void in

        })
    }
}
