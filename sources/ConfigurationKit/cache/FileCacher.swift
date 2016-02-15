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

 - PathExistsAndIsNotDirectory: Given path already exists and is not a directory.
 */
public enum FileCacherError: ErrorType {
    case PathExistsAndIsNotDirectory
}

/**
 *  The FileManager. It exposes everything so that NSFileManager can be mocked.
 */
internal protocol FileManager {
    func createDirectoryAtPath(path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [String : AnyObject]?) throws
    func fileExistsAtPath(path: String, isDirectory: UnsafeMutablePointer<ObjCBool>) -> Bool
    func removeItemAtURL(URL: NSURL) throws
}

extension NSFileManager: FileManager {}

/**
 *  The possible options to save a file with.
 */
public struct FileCachingOptions: OptionSetType {
    /// The raw value.
    public let rawValue: UInt

    /**
     Initializes a `FileCachingOptions` from a raw value.

     - parameter rawValue: The raw value.

     - returns: An initialized a `FileCachingOptions`.
     */
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// No specific options given.
    public static let None = FileCachingOptions(rawValue: 0)

    /// The file will be included in iTunes/iCloud backup.
    public static let IncludeInBackup = FileCachingOptions(rawValue: 1)
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
    internal let fileManager: FileManager

    /**
     Initializes a `FileCacher` with a specific path to store files at.

     - parameter path:        The path to store files at. To ensure no files get
     corrupted in the caching process, give a location in which only
     Configuration files will be saved.
     - parameter options:     The options with which the files saved.

     - throws: Throws an error if given path exists and isn't a directory or if
     directory creation fails.

     - returns: An initialized `FileCacher`.
     */
    public init(path: String, options: FileCachingOptions) throws {
        try self.init(path: path, options: options, fileManager: NSFileManager.defaultManager())
    }

    /**
     Initializes a `FileCacher` with a specific path to store files at.

     - parameter path:        The path to store files at. To ensure no files get
         corrupted in the caching process, give a location in which only
         Configuration files will be saved.
     - parameter options:     The options with which the files saved.
     - parameter fileManager: The file manager.

     - throws: Throws an error if given path exists and isn't a directory or if
     directory creation fails.

     - returns: An initialized `FileCacher`.
     */
    internal init(path: String, options: FileCachingOptions, fileManager: FileManager) throws {
        self.path = path
        self.options = options
        self.fileManager = fileManager

        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExistsAtPath(path, isDirectory: &isDirectory)
        if exists {
            //Ok it exists but is it a directory? If so, it's ok. Else, we got a problem.
            if !isDirectory.boolValue {
                throw FileCacherError.PathExistsAndIsNotDirectory
            }
        }
        else {
            //Let's create the directory
            try fileManager.createDirectoryAtPath(path,
                withIntermediateDirectories: true,
                attributes: nil)
        }
    }

    /**
     Caches data at the location you want (File, Keychain, ?).

     - parameter data: The data to be stored.
     - parameter key:  The key to save the data at.

     - throws: Throws an error if caching failed.
     */
    public func storeData(data: NSData, atKey key: String) throws {
        let URL = NSURL(fileURLWithPath: path).URLByAppendingPathComponent(key)
        try data.writeToURL(URL, options: .DataWritingAtomic)

        try URL.setResourceValue(NSNumber(bool: !options.contains(.IncludeInBackup)),
            forKey: NSURLIsExcludedFromBackupKey)
    }

    /**
     Removes previously stored data.

     - parameter key: The key where the data is supposed.
     */
    public func removeDataAtKey(key: String) {
        let URL = NSURL(fileURLWithPath: path).URLByAppendingPathComponent(key)
        do {
            try fileManager.removeItemAtURL(URL)
        } catch {}
    }

    /**
     Retrieves previously stored data.

     - parameter key: The key where the data is supposed to be stored at.

     - returns: Stored data if existing or nil.
     */
    public func dataAtKey(key: String) -> NSData? {
        let URL = NSURL(fileURLWithPath: path).URLByAppendingPathComponent(key)
        return NSData(contentsOfURL: URL)
    }
}
