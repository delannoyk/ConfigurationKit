//
//  FileCacher.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 09/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 Possible errors that can be thrown.

 - pathExistsAndIsNotDirectory: Given path already exists and is not a directory.
 */
public enum FileCacherError: Error {
    case pathExistsAndIsNotDirectory
}

/**
 *  The FileManager. It exposes everything so that NSFileManager can be mocked.
 */
protocol FileManager {
    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [String : Any]?) throws
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func removeItem(at URL: URL) throws
    func write(_ data: Data, to url: URL, options: FileCachingOptions) throws
    func data(at url: URL) -> Data?
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any]
}

extension Foundation.FileManager: FileManager {
    func write(_ data: Data, to url: URL, options: FileCachingOptions) throws {
        try data.write(to: url, options: .atomic)

        var mutableURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = !options.contains(.includeInBackup)
        try mutableURL.setResourceValues(values)
    }

    func data(at url: URL) -> Data? {
        return try? Data(contentsOf: url)
    }
}

/**
 *  The possible options to save a file with.
 */
public struct FileCachingOptions: OptionSet {
    /// The raw value.
    public let rawValue: UInt

    /**
     Initializes a `FileCachingOptions` from a raw value.

     - parameter rawValue: The raw value.
     */
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// No specific options given.
    public static let none = FileCachingOptions(rawValue: 0)

    /// The file will be included in iTunes/iCloud backup.
    public static let includeInBackup = FileCachingOptions(rawValue: 1)
}

/**
 *  A `FileCacher` is a `Cacher` implementation that saves data in different files.
 */
public struct FileCacher: Cacher {
    /// The path where to store files at.
    public let path: String

    /// The options with which the files saved.
    public let options: FileCachingOptions

    /// The file manager
    let fileManager: FileManager

    /// Initializes a FileCacher.
    public init(path: String, options: FileCachingOptions) {
        self.path = path
        self.options = options
        self.fileManager = Foundation.FileManager.default
    }

    /**
     Initializes a `FileCacher` with a specific path to store files at.

     - parameter path:        The path to store files at. To ensure no files get corrupted in the
         caching process, give a location in which only Configuration files will be saved.
     - parameter options:     The options with which the files saved.
     - parameter fileManager: The file manager.

     - throws: Throws an error if given path exists and isn't a directory or if directory creation
         fails.
     */
    init(path: String, options: FileCachingOptions, fileManager: FileManager = Foundation.FileManager.default) throws {
        self.path = path
        self.options = options
        self.fileManager = fileManager

        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        if exists {
            //Ok it exists but is it a directory? If so, it's ok. Else, we got a problem.
            if !isDirectory.boolValue {
                throw FileCacherError.pathExistsAndIsNotDirectory
            }
        } else {
            //Let's create the directory
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }

    /**
     Caches data at the location you want (File, Keychain, ?).

     - parameter data: The data to be stored.
     - parameter key:  The key to save the data at.

     - throws: Throws an error if caching failed.
     */
    public func store(_ data: Data, at key: String) throws {
        let url = URL(fileURLWithPath: path).appendingPathComponent(key)
        try fileManager.write(data, to: url, options: options)
    }

    /**
     Removes previously stored data.

     - parameter key: The key where the data is supposed.
     */
    public func remove(at key: String) {
        let url = URL(fileURLWithPath: path).appendingPathComponent(key)
        do {
            try fileManager.removeItem(at: url)
        } catch {}
    }

    /**
     Retrieves previously stored data.

     - parameter key: The key where the data is supposed to be stored at.

     - returns: Stored data if existing or nil.
     */
    public func data(at key: String) -> Data? {
        let url = URL(fileURLWithPath: path).appendingPathComponent(key)
        return fileManager.data(at: url)
    }

    /**
     Returns a boolean value indicating whether the cacher has data for a specific key.

     - parameter key: The key where the data is supposed to be stored at.

     - returns: A boolean value indicating whether the cacher has data for a specific key
     */
    public func hasData(at key: String) -> Bool {
        let url = URL(fileURLWithPath: path).appendingPathComponent(key)
        return fileManager.fileExists(atPath: url.path, isDirectory: nil)
    }
}
