//
//  SimpleURLBuilder_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 01/01/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import XCTest
import ConfigurationKit

class SimpleURLBuilder_TestCase: XCTestCase {
    //Testing URLRequest
    func testURLRequest() {
        if let URL = NSURL(string: "https://github.com/delannoyk") {
            let URLRequest = NSURLRequest(URL: URL)
            let URLBuilder = SimpleURLBuilder(urlRequest: URLRequest)
            XCTAssert(URLBuilder.URLRequest() == URLRequest, "URLRequest should be the same as the URLRequest given at initialization")
        }
        else {
            XCTFail("URL isn't valid")
        }
    }

    //Testing URL
    func testURL() {
        if let URL = NSURL(string: "https://github.com/delannoyk") {
            let URLBuilder = SimpleURLBuilder(URL: URL)
            XCTAssert(URLBuilder.URLRequest().URL == URL, "URL of URLRequest should be the same as the URL given at initialization")
        }
        else {
            XCTFail("URL isn't valid")
        }
    }
}
