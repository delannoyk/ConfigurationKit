//
//  RemoteConfigurationCache.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

public struct RemoteConfigurationCache {
    private let cacheURL: NSURL
    private let bootstrapConfigurationFilePath: String?
    private let encryptor: RemoteConfigurationCacheEncryptor?

    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    public init(identifier: String, bootstrapConfigurationFilePath: String? = nil, encryptor: RemoteConfigurationCacheEncryptor? = nil) throws {
        let configurationDirectory = NSURL(fileURLWithPath: String.documentPath).URLByAppendingPathComponent("ConfigurationKit")
        try configurationDirectory.createDirectoryIfNecesserary()

        cacheURL = configurationDirectory

        self.bootstrapConfigurationFilePath = bootstrapConfigurationFilePath
        self.encryptor = encryptor
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Caching
    ////////////////////////////////////////////////////////////////////////////

    internal func cacheData(data: NSData?, inFile file: String) throws {
        let URL = cacheURL.URLByAppendingPathComponent(file)
        if let data = data {
            let finalData = encryptor?.encryptedData(fromData: data) ?? data
            try finalData.writeToURL(URL, options: .AtomicWrite)
        }
        else {
            if let path = URL.path {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            }
        }
    }

    internal func cachedData(inFile file: String) -> NSData? {
        let URL = cacheURL.URLByAppendingPathComponent(file)
        if let data = NSData(contentsOfURL: URL) {
            return encryptor?.decryptedData(fromData: data) ?? data
        }
        return nil
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Bootstrap
    ////////////////////////////////////////////////////////////////////////////

    internal func bootstrapConfigurationData() -> NSData? {
        if let bootstrapConfigurationFilePath = bootstrapConfigurationFilePath {
            return NSData(contentsOfFile: bootstrapConfigurationFilePath)
        }
        return nil
    }

    ////////////////////////////////////////////////////////////////////////////
}
