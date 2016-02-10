//
//  RemoteConfiguration.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

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

        setCachedProperties()

        fileDownloader.start()
    }


    deinit {
        fileDownloader.stop()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Caching
    ////////////////////////////////////////////////////////////////////////////

    private func setCachedProperties() {
        if let data = cache.cachedData(inFile: RemoteConfigurationConfigurationKey),
            configuration = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: String] {
                self.configuration = configuration
        }
        else if let data = cache.bootstrapConfigurationData(),
            configuration = parser.parseData(data).result {
                self.configuration = configuration
        }

        if let data = cache.cachedData(inFile: RemoteConfigurationDateKey),
            date = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDate {
                configurationDate = date
        }

        if let data = cache.cachedData(inFile: RemoteConfigurationLastCycleDateKey),
            date = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDate {
                lastCycleDate = date
        }

        if let data = cache.cachedData(inFile: RemoteConfigurationLastCycleErrorKey),
            error = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSError {
                lastCycleError = error
        }
    }

    private func cacheConfigurationInfo(config config: Bool, date: Bool) throws {
        if config {
            try cache.cacheData(NSKeyedArchiver.archivedDataWithRootObject(configuration), inFile: RemoteConfigurationConfigurationKey)
        }
        if date {
            if let configurationDate = configurationDate {
                try cache.cacheData(NSKeyedArchiver.archivedDataWithRootObject(configurationDate), inFile: RemoteConfigurationDateKey)
            }
        }
    }

    private func cacheCycleInfo() throws {
        if let lastCycleDate = lastCycleDate {
            try cache.cacheData(NSKeyedArchiver.archivedDataWithRootObject(lastCycleDate), inFile: RemoteConfigurationLastCycleDateKey)
        }

        if let lastCycleError = lastCycleError {
            try cache.cacheData(NSKeyedArchiver.archivedDataWithRootObject(lastCycleError), inFile: RemoteConfigurationLastCycleErrorKey)
        }
        else {
            try cache.cacheData(nil, inFile: RemoteConfigurationLastCycleErrorKey)
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Subscript & Object for key
    ////////////////////////////////////////////////////////////////////////////

    public subscript(key: String) -> String? {
        return configuration[key]
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
            return fileDownloader.refreshWhenEnteringForeground
        }
        set {
            fileDownloader.refreshWhenEnteringForeground = newValue
        }
    }

    public var refreshOnIntervalBasis: Bool {
        get {
            return fileDownloader.refreshOnIntervalBasis
        }
        set {
            fileDownloader.refreshOnIntervalBasis = newValue
        }
    }

    public var refreshInterval: NSTimeInterval {
        get {
            return fileDownloader.refreshInterval
        }
        set {
            fileDownloader.refreshInterval = newValue
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: FileDownloader handler
    ////////////////////////////////////////////////////////////////////////////

    private func fileDownloaderWillStart() -> NSURLRequest {
        postNotificationNamed(RemoteConfigurationWillStartNewCycleNotification)
        return builder.URLRequest()
    }

    private func fileDownloaderCompletedWithData(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) {
        if let data = data {
            //Parsing data
            let result = parser.parseData(data)
            if let configuration = result.result {
                //Analyzing key changes & new value
                let differences = self.configuration.delta(configuration)
                self.configuration = configuration

                differences.forEach { change in
                    let name: String
                    let userInfo: [NSObject: AnyObject]

                    switch change {
                    case .Addition(let key, let value):
                        name = RemoteConfigurationNewKeyDetectedNotification
                        userInfo = [RemoteConfigurationKeyKey: key,
                            RemoteConfigurationNewValueKey: value]

                    case .Change(let key, let oldValue, let newValue):
                        name = RemoteConfigurationValueChangedNotification
                        userInfo = [RemoteConfigurationKeyKey: key,
                            RemoteConfigurationOldValueKey: oldValue,
                            RemoteConfigurationNewValueKey: newValue]

                    case .Removal(let key, let value):
                        name = RemoteConfigurationKeyRemovalDetectedNotification
                        userInfo = [RemoteConfigurationKeyKey:
                            key, RemoteConfigurationOldValueKey: value]
                    }

                    postNotificationNamed(name, userInfo: userInfo)
                }

                //Caching & saving date
                configurationDate = NSDate()
                lastCycleError = nil
                do {
                    try cacheConfigurationInfo(config: (differences.count > 0), date: true)
                } catch {}
            }
            else {
                lastCycleError = result.error
            }
        }
        else {
            lastCycleError = error
        }

        //Saving date
        lastCycleDate = NSDate()
        do {
            try cacheCycleInfo()
        } catch {}
        postNotificationNamed(RemoteConfigurationDidEndCycleNotification)
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Notification
    ////////////////////////////////////////////////////////////////////////////

    private func postNotificationNamed(name: String, userInfo: [NSObject: AnyObject]? = nil) {
        dispatch_sync(dispatch_get_main_queue(), {[weak self] () -> Void in
            let note = NSNotification(name: name, object: self, userInfo: userInfo)
            NSNotificationCenter.defaultCenter().postNotification(note)
        })
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Description
    ////////////////////////////////////////////////////////////////////////////

    override public var description: String {
        return configuration.description
    }

    override public var debugDescription: String {
        return configuration.debugDescription
    }

    ////////////////////////////////////////////////////////////////////////////
}

////////////////////////////////////////////////////////////////////////////
