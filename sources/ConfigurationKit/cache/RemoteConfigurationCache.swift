//
//  RemoteConfigurationCache.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

public final class RemoteConfigurationCache: NSObject {
    private let cachePath: String
    private let encryptor: RemoteConfigurationCacheEncryptor?

    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    public init(identifier: String, encryptor: RemoteConfigurationCacheEncryptor? = nil) {
        let configurationDirectory = String.documentPath.stringByAppendingPathComponent("ConfigurationKit")
        configurationDirectory.createDirectoryIfNecesserary()

        self.cachePath = configurationDirectory.stringByAppendingPathComponent("\(identifier).rconf")
        self.cachePath.createDirectoryIfNecesserary()

        self.encryptor = encryptor
        super.init()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Caching
    ////////////////////////////////////////////////////////////////////////////

    internal func cacheData(data: NSData?, inFile file: String) {
        let path = self.cachePath.stringByAppendingPathComponent(file)
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
        if let data = NSData(contentsOfFile: self.cachePath.stringByAppendingPathComponent(file)) {
            if let encryptor = self.encryptor {
                return encryptor.decryptedData(fromData: data)
            }
            return data
        }
        return nil
    }

    ////////////////////////////////////////////////////////////////////////////
}
