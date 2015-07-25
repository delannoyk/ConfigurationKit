//
//  RemoteConfigurationCache.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

public struct RemoteConfigurationCache {
    private let cachePath: String
    private let bootstrapConfigurationFilePath: String?
    private let encryptor: RemoteConfigurationCacheEncryptor?

    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    public init(identifier: String, bootstrapConfigurationFilePath: String? = nil, encryptor: RemoteConfigurationCacheEncryptor? = nil) {
        let configurationDirectory = String.documentPath.stringByAppendingPathComponent("ConfigurationKit")
        configurationDirectory.createDirectoryIfNecesserary()

        cachePath = configurationDirectory.stringByAppendingPathComponent("\(identifier).rconf")
        cachePath.createDirectoryIfNecesserary()

        self.bootstrapConfigurationFilePath = bootstrapConfigurationFilePath

        self.encryptor = encryptor
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Caching
    ////////////////////////////////////////////////////////////////////////////

    internal func cacheData(data: NSData?, inFile file: String) {
        let path = cachePath.stringByAppendingPathComponent(file)
        if let data = data {
            let toWrite: NSData = {
                if let encryptor = self.encryptor {
                    return encryptor.encryptedData(fromData: data)
                }
                return data
            }()
            toWrite.writeToFile(path, atomically: true)
        }
        else {
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
        }
    }

    internal func cachedData(inFile file: String) -> NSData? {
        if let data = NSData(contentsOfFile: cachePath.stringByAppendingPathComponent(file)) {
            if let encryptor = encryptor {
                return encryptor.decryptedData(fromData: data)
            }
            return data
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
