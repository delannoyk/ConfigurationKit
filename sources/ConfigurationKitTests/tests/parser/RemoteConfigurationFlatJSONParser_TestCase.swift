//
//  RemoteConfigurationFlatJSONParser_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 25/07/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import XCTest
import ConfigurationKit

class RemoteConfigurationFlatJSONParser_TestCase: XCTestCase {
    //Test parsing
    func testSuccessParsing() {
        let URL = NSBundle(forClass: self.dynamicType).URLForResource("SampleConfig", withExtension: "json")
        let data = NSData(contentsOfURL: URL!)!

        let parser = RemoteConfigurationFlatJSONParser()
        let result = parser.parseData(data)

        XCTAssert(result.result != nil, "The parsing should have gone well")
        XCTAssert(result.result!["Foo1"] == "Bar1", "The parsing result isn't correct")
        XCTAssert(result.result!["Foo2"] == "Bar2", "The parsing result isn't correct")
        XCTAssert(result.result!["Foo3"] == "Bar3", "The parsing result isn't correct")
        XCTAssert(result.result!["Foo4"] == "Bar4", "The parsing result isn't correct")
        XCTAssert(result.result!["Foo5"] == "Bar5", "The parsing result isn't correct")
        XCTAssert(result.result!["Foo6"] == "Bar6", "The parsing result isn't correct")
        XCTAssert(result.result!["Foo7"] == "Bar7", "The parsing result isn't correct")
        XCTAssert(result.result!["Foo8"] == "Bar8", "The parsing result isn't correct")
        XCTAssert(result.result!["Foo9"] == "Bar9", "The parsing result isn't correct")
    }

    func testFailureParsing() {
        let URL = NSBundle(forClass: self.dynamicType).URLForResource("SampleConfig", withExtension: "plist")
        let data = NSData(contentsOfURL: URL!)!

        let parser = RemoteConfigurationFlatJSONParser()
        let result = parser.parseData(data)

        XCTAssert(result.result == nil, "The parsing shouldn't have gone well")
    }
}
