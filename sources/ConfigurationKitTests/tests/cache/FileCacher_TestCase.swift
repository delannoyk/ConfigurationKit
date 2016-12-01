//
//  FileCacher_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

class FakeManager: ConfigurationKit.FileManager {
    var customInfo = [String: Data]()

    var onCreate: ((String, Bool, [String: Any]?) throws -> ())?
    var onFileExists: ((String, UnsafeMutablePointer<ObjCBool>?) -> Bool)?
    var onRemove: ((URL) throws -> ())?
    var onWrite: ((Data, URL, FileCachingOptions) throws -> ())?
    var onData: ((URL) -> Data?)?
    var onAttributes: ((String) throws -> [FileAttributeKey: Any])?

    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [String : Any]?) throws {
        try onCreate?(path, createIntermediates, attributes)
    }

    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        return onFileExists?(path, isDirectory) ?? true
    }

    func removeItem(at URL: URL) throws {
        try onRemove?(URL)
    }

    func write(_ data: Data, to url: URL, options: FileCachingOptions) throws {
        try onWrite?(data, url, options)
    }

    func data(at url: URL) -> Data? {
        return onData?(url)
    }

    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any] {
        return try onAttributes?(path) ?? [:]
    }
}

class FileCacher_TestCase: XCTestCase {
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

    func testCreationWherePathExistsAndIsADirectory() {
        let manager = FakeManager()

        manager.onFileExists = { a, b in
            b?.pointee = true
            return true
        }

        do {
            let _ = try FileCacher(path: path, options: [], fileManager: manager)
        } catch { XCTFail() }
    }

    func testCreationWherePathExistsAndIsNotADirectory() {
        let manager = FakeManager()

        manager.onFileExists = { a, b in
            b?.pointee = false
            return true
        }

        do {
            let _ = try FileCacher(path: path, options: [], fileManager: manager)
            XCTFail()
        } catch { }
    }

    func testCreationWherePathDoesntExistButCreationThrows() {
        let manager = FakeManager()

        manager.onCreate = { a, b, c in
            throw NSError(domain: "", code: -1, userInfo: nil)
        }
        manager.onFileExists = { a, b in
            b?.pointee = false
            return false
        }

        do {
            let _ = try FileCacher(path: path, options: [], fileManager: manager)
            XCTFail()
        } catch { }
    }

    func testCreationWherePathDoesntExistAndCreationSuccess() {
        let manager = FakeManager()

        manager.onFileExists = { a, b in
            b?.pointee = false
            return false
        }

        do {
            let _ = try FileCacher(path: path, options: [], fileManager: manager)
        } catch { XCTFail() }
    }

    func testStoring() {
        let e = expectation(description: "Waiting for onWrite")

        let manager = FakeManager()
        manager.onFileExists = { a, b in
            b?.pointee = false
            return false
        }
        manager.onWrite = { data, url, options in
            e.fulfill()
        }

        let cacher = try! FileCacher(path: path, options: [], fileManager: manager)
        try! cacher.store("abc".data(using: .ascii)!, at: "key")

        waitForExpectations(timeout: 1) { e in
            XCTAssertNil(e)
        }
    }

    func testRetrievingWithStore() {
        let manager = FakeManager()
        manager.onFileExists = { a, b in
            b?.pointee = false
            return false
        }
        manager.onWrite = { (data: Data, url: URL, options: FileCachingOptions) in
            manager.customInfo[url.path] = data
        }
        manager.onData = { url in
            return manager.customInfo[url.path]
        }
        manager.onRemove = { url in
            manager.customInfo.removeValue(forKey: url.path)
        }

        let cacher = try! FileCacher(path: path, options: [], fileManager: manager)

        manager.onFileExists = { a, b in
            return manager.customInfo[a] != nil
        }

        try! cacher.store("abc".data(using: .ascii)!, at: "key")

        let data: Data! = cacher.data(at: "key")
        XCTAssertNotNil(data)
        XCTAssertEqual(String(data: data, encoding: .ascii), "abc")
        XCTAssert(cacher.hasData(at: "key"))

        cacher.remove(at: "key")
        XCTAssertNil(cacher.data(at: "key"))
        XCTAssertFalse(cacher.hasData(at: "key"))
    }
}
