//
//  KDERemoteConfigurationCache.swift
//  KDEConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

public final class KDERemoteConfigurationCache: NSObject {
    private let cachePath: String
    private let encryptCache: Bool

    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    public init(identifier: String, encryptCache: Bool) {
        let configurationDirectory = String.documentPath.stringByAppendingPathComponent("ConfigurationKit")
        configurationDirectory.createDirectoryIfNecesserary()

        self.cachePath = configurationDirectory.stringByAppendingPathComponent("\(identifier).rconf")
        self.cachePath.createDirectoryIfNecesserary()

        self.encryptCache = encryptCache
        super.init()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Caching
    ////////////////////////////////////////////////////////////////////////////

    internal func cacheData(data: NSData, inFile file: String) {
        //TODO: encryptCache?
        data.writeToFile(self.cachePath.stringByAppendingPathComponent(file), atomically: true)
    }

    internal func cachedData(inFile file: String) -> NSData? {
        //TODO: encryptCache?
        return NSData(contentsOfFile: self.cachePath.stringByAppendingPathComponent(file))
    }

    ////////////////////////////////////////////////////////////////////////////
}
