//
//  SimpleURLRequestBuilder_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 01/01/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import XCTest
import ConfigurationKit

class SimpleURLRequestBuilder_TestCase: XCTestCase {
    //Testing URLRequest
    func testURLRequest() {
        let url = URL(string: "https://github.com/delannoyk")!
        let request = URLRequest(url: url)
        let requestBuilder = SimpleURLRequestBuilder(urlRequest: request)
        XCTAssert(requestBuilder.URLRequest() == request, "URLRequest should be the same as the URLRequest given at initialization")
    }

    //Testing URL
    func testURL() {
        let url = URL(string: "https://github.com/delannoyk")
        let requestBuilder = SimpleURLRequestBuilder(URL: url)
        XCTAssert(requestBuilder.URLRequest().url == url, "URL of URLRequest should be the same as the URL given at initialization")
    }
}
