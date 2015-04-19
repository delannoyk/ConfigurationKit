//
//  RemoteConfiguration.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

// MARK: - Notification
////////////////////////////////////////////////////////////////////////////

public let RemoteConfigurationWillStartNewCycleNotification = "RemoteConfigurationWillStartNewCycleNotification"
public let RemoteConfigurationDidEndCycleNotification = "RemoteConfigurationDidEndCycleNotification"

public let RemoteConfigurationNewKeyDetectedNotification = "RemoteConfigurationNewKeyDetectedNotification"
public let RemoteConfigurationValueChangedNotification = "RemoteConfigurationValueChangedNotification"
public let RemoteConfigurationKeyRemovalDetectedNotification = "RemoteConfigurationKeyRemovalDetectedNotification"

public let RemoteConfigurationKeyKey = "RemoteConfigurationKeyKey"
public let RemoteConfigurationNewValueKey = "RemoteConfigurationNewValueKey"
public let RemoteConfigurationOldValueKey = "RemoteConfigurationOldValueKey"

////////////////////////////////////////////////////////////////////////////


// MARK: - Cache keys
////////////////////////////////////////////////////////////////////////////

private let RemoteConfigurationConfigurationKey = "configuration.conf"
private let RemoteConfigurationDateKey = "configuration.date"
private let RemoteConfigurationLastCycleDateKey = "cycle.date"
private let RemoteConfigurationLastCycleErrorKey = "cycle.error"

////////////////////////////////////////////////////////////////////////////


// MARK: - RemoteConfiguration
////////////////////////////////////////////////////////////////////////////

public final class RemoteConfiguration: NSObject {
    private let builder: URLBuilder
    private let parser: RemoteConfigurationParser
    private let cache: RemoteConfigurationCache

    internal private(set) var configuration: [String: String]

    private lazy var fileDownloader: FileDownloader = {
        let downloader = FileDownloader(beginBlock: {[weak self] () -> NSURLRequest? in
            return self?.fileDownloaderWillStart()
        })
        downloader.onRefreshComplete = {[weak self] (data, response, error) -> Void in
            self?.fileDownloaderCompletedWithData(data, response: response, error: error)
            return
        }
        return downloader
    }()


    // MARK: Initialization & Deinitialization
    ////////////////////////////////////////////////////////////////////////////

    public convenience init(URL: NSURL, parser: RemoteConfigurationParser, cache: RemoteConfigurationCache) {
        self.init(URLRequest: NSURLRequest(URL: URL), parser: parser, cache: cache)
    }

    public convenience init(URLRequest: NSURLRequest, parser: RemoteConfigurationParser, cache: RemoteConfigurationCache) {
        self.init(builder: SimpleURLBuilder(URLRequest: URLRequest), parser: parser, cache: cache)
    }

    public init(builder: URLBuilder, parser: RemoteConfigurationParser, cache: RemoteConfigurationCache) {
        self.builder = builder
        self.parser = parser
        self.cache = cache
        self.configuration = [:]
        super.init()

        self.setCachedProperties()

        self.fileDownloader.start()
    }


    deinit {
        self.fileDownloader.stop()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Caching
    ////////////////////////////////////////////////////////////////////////////

    private func setCachedProperties() {
        if let data = self.cache.cachedData(inFile: RemoteConfigurationConfigurationKey), configuration = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: String] {
            self.configuration = configuration
        }
        else {
            //TODO: load bootstrap
        }

        if let data = self.cache.cachedData(inFile: RemoteConfigurationDateKey), date = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDate {
            self.configurationDate = date
        }
        else {
            //TODO: bootstrap?
        }

        if let data = self.cache.cachedData(inFile: RemoteConfigurationLastCycleDateKey), date = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDate {
            self.lastCycleDate = date
        }

        if let data = self.cache.cachedData(inFile: RemoteConfigurationLastCycleErrorKey), error = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSError {
            self.lastCycleError = error
        }
    }

    private func cacheConfigurationInfo(#config: Bool, date: Bool) {
        if config {
            self.cache.cacheData(NSKeyedArchiver.archivedDataWithRootObject(self.configuration), inFile: RemoteConfigurationConfigurationKey)
        }
        if date {
            if let configurationDate = self.configurationDate {
                self.cache.cacheData(NSKeyedArchiver.archivedDataWithRootObject(configurationDate), inFile: RemoteConfigurationDateKey)
            }
        }
    }

    private func cacheCycleInfo() {
        if let lastCycleDate = self.lastCycleDate {
            self.cache.cacheData(NSKeyedArchiver.archivedDataWithRootObject(lastCycleDate), inFile: RemoteConfigurationLastCycleDateKey)
        }

        if let lastCycleError = self.lastCycleError {
            self.cache.cacheData(NSKeyedArchiver.archivedDataWithRootObject(lastCycleError), inFile: RemoteConfigurationLastCycleErrorKey)
        }
        else {
            self.cache.cacheData(nil, inFile: RemoteConfigurationLastCycleErrorKey)
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Subscript & Object for key
    ////////////////////////////////////////////////////////////////////////////

    public subscript(key: String) -> String? {
        return self.configuration[key]
    }

    public func stringForKey(key: String) -> String? {
        return self[key]
    }

    public func objectForKey(key: String) -> String? {
        return self[key]
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Properties
    ////////////////////////////////////////////////////////////////////////////

    public private(set) var configurationDate: NSDate?

    public private(set) var lastCycleDate: NSDate?

    public private(set) var lastCycleError: NSError?

    public var shouldCacheData = true

    public var refreshWhenEnteringForeground: Bool {
        get {
            return self.fileDownloader.refreshWhenEnteringForeground
        }
        set {
            self.fileDownloader.refreshWhenEnteringForeground = newValue
        }
    }

    public var refreshOnIntervalBasis: Bool {
        get {
            return self.fileDownloader.refreshOnIntervalBasis
        }
        set {
            self.fileDownloader.refreshOnIntervalBasis = newValue
        }
    }

    public var refreshInterval: NSTimeInterval {
        get {
            return self.fileDownloader.refreshInterval
        }
        set {
            self.fileDownloader.refreshInterval = newValue
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: FileDownloader handler
    ////////////////////////////////////////////////////////////////////////////

    private func fileDownloaderWillStart() -> NSURLRequest {
        self.postNotificationNamed(RemoteConfigurationWillStartNewCycleNotification)
        return self.builder.URLRequest()
    }

    private func fileDownloaderCompletedWithData(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) {
        if let data = data {
            //Parsing data
            let result = self.parser.parseData(data)
            if let configuration = result.result {
                var hasChanges = false

                //Analyzing key changes & new value
                for (key, value) in configuration {
                    if let existing = self[key] {
                        if existing != value {
                            hasChanges = true

                            self.postNotificationNamed(RemoteConfigurationValueChangedNotification, userInfo: [
                                RemoteConfigurationKeyKey: key,
                                RemoteConfigurationOldValueKey: existing,
                                RemoteConfigurationNewValueKey: value
                            ])
                        }
                    }
                    else {
                        hasChanges = true

                        self.postNotificationNamed(RemoteConfigurationNewKeyDetectedNotification, userInfo: [
                            RemoteConfigurationKeyKey: key,
                            RemoteConfigurationNewValueKey: value
                        ])
                    }
                }

                //Analyzing key removal
                let newConfigurationKeys = configuration.keys.array
                let removed = filter(self.configuration.keys.array, { element in
                    if !contains(newConfigurationKeys, element) {
                        hasChanges = true

                        self.postNotificationNamed(RemoteConfigurationKeyRemovalDetectedNotification, userInfo: [
                            RemoteConfigurationKeyKey: element,
                            RemoteConfigurationOldValueKey: self[element] ?? ""
                        ])
                        return true
                    }
                    return false
                })

                //Caching & saving date
                self.configuration = configuration
                self.configurationDate = NSDate()
                self.lastCycleError = nil
                self.cacheConfigurationInfo(config: hasChanges, date: true)
            }
            else {
                self.lastCycleError = result.error
            }
        }
        else {
            self.lastCycleError = error
        }

        //Saving date
        self.lastCycleDate = NSDate()
        self.cacheCycleInfo()
        self.postNotificationNamed(RemoteConfigurationDidEndCycleNotification)
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Notification
    ////////////////////////////////////////////////////////////////////////////

    private func postNotificationNamed(name: String, userInfo: [NSObject: AnyObject]? = nil) {
        dispatch_sync(dispatch_get_main_queue(), {[weak self] () -> Void in
            var note = NSNotification(name: name, object: self, userInfo: userInfo)
            NSNotificationCenter.defaultCenter().postNotification(note)
        })
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Description
    ////////////////////////////////////////////////////////////////////////////

    override public var description: String {
        return self.configuration.description
    }

    override public var debugDescription: String {
        return self.configuration.debugDescription
    }

    ////////////////////////////////////////////////////////////////////////////
}

////////////////////////////////////////////////////////////////////////////
