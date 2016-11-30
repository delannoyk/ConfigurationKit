//
//  PListParser_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 25/07/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

class PListParser_TestCase: XCTestCase {
    //Test parsing
    func testSuccessParsing() {
        let URL = Bundle(for: type(of: self)).url(forResource: "SampleConfig", withExtension: "plist")
        let data = try! Data(contentsOf: URL!)

        let parser = PListParser()
        let result: [String: String]
        do {
            result = try parser.parse(data)
        } catch {
            XCTFail()
            return
        }

        XCTAssert(result["Foo1"] == "Bar1", "The parsing result isn't correct")
        XCTAssert(result["Foo2"] == "Bar2", "The parsing result isn't correct")
        XCTAssert(result["Foo3"] == "Bar3", "The parsing result isn't correct")
        XCTAssert(result["Foo4"] == "Bar4", "The parsing result isn't correct")
        XCTAssert(result["Foo5"] == "Bar5", "The parsing result isn't correct")
        XCTAssert(result["Foo6"] == "Bar6", "The parsing result isn't correct")
        XCTAssert(result["Foo7"] == "Bar7", "The parsing result isn't correct")
        XCTAssert(result["Foo8"] == "Bar8", "The parsing result isn't correct")
        XCTAssert(result["Foo9"] == "Bar9", "The parsing result isn't correct")
    }

    func testFailureParsing() {
        let URL = Bundle(for: type(of: self)).url(forResource: "SampleConfig", withExtension: "json")
        let data = try! Data(contentsOf: URL!)

        let parser = PListParser()
        do {
            let _ = try parser.parse(data)
            XCTFail()
        } catch {}
    }
}
