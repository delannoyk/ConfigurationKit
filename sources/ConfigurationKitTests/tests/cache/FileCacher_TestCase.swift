//
//  FileCacher_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

struct FakeManager: FileManager {
    var customInfo = [String: NSData]()

    var onCreate: ((String, Bool, [String: AnyObject]?) throws -> ())?
    var onFileExists: ((String, UnsafeMutablePointer<ObjCBool>) -> Bool)?
    var onRemove: (NSURL throws -> ())?
    var onWrite: ((NSData, NSURL, FileCachingOptions) throws -> ())?
    var onData: (NSURL -> NSData?)?

    func createDirectoryAtPath(path: String,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [String : AnyObject]?) throws {
            try onCreate?(path, createIntermediates, attributes)
    }

    func fileExistsAtPath(path: String, isDirectory: UnsafeMutablePointer<ObjCBool>) -> Bool {
        return onFileExists?(path, isDirectory) ?? true
    }

    func removeItemAtURL(URL: NSURL) throws {
        try onRemove?(URL)
    }

    func writeData(data: NSData, atURL URL: NSURL, withOptions options: FileCachingOptions) throws {
        try onWrite?(data, URL, options)
    }

    func dataAtURL(URL: NSURL) -> NSData? {
        return onData?(URL)
    }
}

class FileCacher_TestCase: XCTestCase {
    let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]

    func testCreationWherePathExistsAndIsADirectory() {
        var manager = FakeManager()

        manager.onFileExists = { a, b in
            b.memory = true
            return true
        }

        do {
            let _ = try FileCacher(path: path, options: [], fileManager: manager)
        } catch { XCTFail() }
    }

    func testCreationWherePathExistsAndIsNotADirectory() {
        var manager = FakeManager()

        manager.onFileExists = { a, b in
            b.memory = false
            return true
        }

        do {
            let _ = try FileCacher(path: path, options: [], fileManager: manager)
            XCTFail()
        } catch { }
    }

    func testCreationWherePathDoesntExistButCreationThrows() {
        var manager = FakeManager()

        manager.onCreate = { a, b, c in
            throw NSError(domain: "", code: -1, userInfo: nil)
        }
        manager.onFileExists = { a, b in
            b.memory = false
            return false
        }

        do {
            let _ = try FileCacher(path: path, options: [], fileManager: manager)
            XCTFail()
        } catch { }
    }

    func testCreationWherePathDoesntExistAndCreationSuccess() {
        var manager = FakeManager()

        manager.onFileExists = { a, b in
            b.memory = false
            return false
        }

        do {
            let _ = try FileCacher(path: path, options: [], fileManager: manager)
        } catch { XCTFail() }
    }

    func testStoring() {
        let expectation = expectationWithDescription("Waiting for onWrite")

        var manager = FakeManager()
        manager.onFileExists = { a, b in
            b.memory = false
            return false
        }
        manager.onWrite = { data, url, options in
            expectation.fulfill()
        }

        let cacher = try! FileCacher(path: path, options: [], fileManager: manager)
        try! cacher.storeData("abc".dataUsingEncoding(NSASCIIStringEncoding)!, atKey: "key")

        waitForExpectationsWithTimeout(1) { e in
            XCTAssertNil(e)
        }
    }

    func testRetrievingWithStore() {
        var manager = FakeManager()
        manager.onFileExists = { a, b in
            b.memory = false
            return false
        }
        manager.onWrite = { (data: NSData, url: NSURL, options: FileCachingOptions) in
            manager.customInfo[url.absoluteString] = data
        }
        manager.onData = { url in
            return manager.customInfo[url.absoluteString]
        }
        manager.onRemove = { url in
            manager.customInfo.removeValueForKey(url.absoluteString)
        }

        let cacher = try! FileCacher(path: path, options: [], fileManager: manager)
        try! cacher.storeData("abc".dataUsingEncoding(NSASCIIStringEncoding)!, atKey: "key")

        let data: NSData! = cacher.dataAtKey("key")
        XCTAssertNotNil(data)
        XCTAssertEqual(String(data: data, encoding: NSASCIIStringEncoding), "abc")

        cacher.removeDataAtKey("key")
        XCTAssertNil(cacher.dataAtKey("key"))
    }
}
