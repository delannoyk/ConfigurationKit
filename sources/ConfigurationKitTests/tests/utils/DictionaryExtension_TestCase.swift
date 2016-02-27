//
//  DictionaryExtension_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 09/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

class DictionaryExtension_TestCase: XCTestCase {
    func testChanges() {
        let d1 = ["10": "a", "11": "b", "12": "c", "13": "d", "14": "e", "15": "f"]
        let d2 = ["10": "A", "11": "B", "12": "C", "13": "D", "14": "E", "15": "F"]
        let diff = d1.delta(d2)

        XCTAssert(diff.count == d1.count)
        if diff.count == 0 {
            XCTFail()
        }

        //Testing changes
        diff.forEach {
            XCTAssert($0.isChange)
            XCTAssert(!$0.isAddition)
            XCTAssert(!$0.isRemoval)
            XCTAssert($0.oldValue == d1[$0.key])
            XCTAssert($0.newValue == d2[$0.key])
            XCTAssert($0.oldValue == $0.newValue?.lowercaseString)
        }
    }

    func testAdditions() {
        let d1 = [String: String]()
        let d2 = ["10": "A", "11": "B", "12": "C", "13": "D", "14": "E", "15": "F"]
        let diff = d1.delta(d2)

        XCTAssert(diff.count == d2.count)
        if diff.count == 0 {
            XCTFail()
        }

        //Testing changes
        diff.forEach {
            XCTAssert($0.isAddition)
            XCTAssert(!$0.isChange)
            XCTAssert(!$0.isRemoval)
            XCTAssert($0.oldValue == nil)
            XCTAssert($0.newValue == d2[$0.key])
        }
    }

    func testRemovals() {
        let d1 = ["10": "A", "11": "B", "12": "C", "13": "D", "14": "E", "15": "F"]
        let d2 = [String: String]()
        let diff = d1.delta(d2)

        XCTAssert(diff.count == d1.count)
        if diff.count == 0 {
            XCTFail()
        }

        //Testing changes
        diff.forEach {
            XCTAssert($0.isRemoval)
            XCTAssert(!$0.isAddition)
            XCTAssert(!$0.isChange)
            XCTAssert($0.oldValue == d1[$0.key])
            XCTAssert($0.newValue == nil)
        }
    }
}
