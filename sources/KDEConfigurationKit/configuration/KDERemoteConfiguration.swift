//
//  KDERemoteConfiguration.swift
//  KDERemoteConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

// MARK: - Notification
////////////////////////////////////////////////////////////////////////////

public let KDERemoteConfigurationWillStartNewCycleNotification = "KDERemoteConfigurationWillStartNewCycleNotification"
public let KDERemoteConfigurationDidEndCycleNotification = "KDERemoteConfigurationDidEndCycleNotification"

public let KDERemoteConfigurationNewKeyDetectedNotification = "KDERemoteConfigurationNewKeyDetectedNotification"
public let KDERemoteConfigurationValueChangedNotification = "KDERemoteConfigurationValueChangedNotification"
public let KDERemoteConfigurationKeyRemovalDetectedNotification = "KDERemoteConfigurationKeyRemovalDetectedNotification"

public let KDERemoteConfigurationKeyKey = "KDERemoteConfigurationKeyKey"
public let KDERemoteConfigurationNewValueKey = "KDERemoteConfigurationNewValueKey"
public let KDERemoteConfigurationOldValueKey = "KDERemoteConfigurationOldValueKey"

////////////////////////////////////////////////////////////////////////////


// MARK: - RemoteConfiguration
////////////////////////////////////////////////////////////////////////////

public final class KDERemoteConfiguration: NSObject {
    private let URLBuilder: KDEURLBuilder
    private let parser: KDERemoteConfigurationParser
    private let cache: KDERemoteConfigurationCache

    internal private(set) var configuration: [String: String]

    private lazy var fileDownloader: KDEFileDownloader = {
        let downloader = KDEFileDownloader(beginBlock: {[weak self] () -> NSURLRequest? in
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

    public convenience init(URL: NSURL, parser: KDERemoteConfigurationParser, cache: KDERemoteConfigurationCache) {
        self.init(URLRequest: NSURLRequest(URL: URL), parser: parser, cache: cache)
    }

    public convenience init(URLRequest: NSURLRequest, parser: KDERemoteConfigurationParser, cache: KDERemoteConfigurationCache) {
        self.init(URLBuilder: KDESimpleURLBuilder(URLRequest: URLRequest), parser: parser, cache: cache)
    }

    public init(URLBuilder: KDEURLBuilder, parser: KDERemoteConfigurationParser, cache: KDERemoteConfigurationCache) {
        self.URLBuilder = URLBuilder
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


    // MARK: KDEFileDownloader handler
    ////////////////////////////////////////////////////////////////////////////

    private func fileDownloaderWillStart() -> NSURLRequest {
        self.postNotificationNamed(KDERemoteConfigurationWillStartNewCycleNotification)
        return self.URLBuilder.URLRequest()
    }

    private func fileDownloaderCompletedWithData(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) {
        if let data = data {
            //Parsing data
            let result = self.parser.parseData(data)
            if let configuration = result.result {
                //Analyzing key changes & new value
                for (key, value) in configuration {
                    if let existing = self[key] {
                        if existing != value {
                            self.postNotificationNamed(KDERemoteConfigurationValueChangedNotification, userInfo: [
                                KDERemoteConfigurationKeyKey: key,
                                KDERemoteConfigurationOldValueKey: existing,
                                KDERemoteConfigurationNewValueKey: value
                                ])
                        }
                    }
                    else {
                        self.postNotificationNamed(KDERemoteConfigurationNewKeyDetectedNotification, userInfo: [
                            KDERemoteConfigurationKeyKey: key,
                            KDERemoteConfigurationNewValueKey: value
                            ])
                    }
                }

                //Analyzing key removal
                let newConfigurationKeys = configuration.keys.array
                let removed = filter(self.configuration.keys.array, { element in
                    if !contains(newConfigurationKeys, element) {
                        self.postNotificationNamed(KDERemoteConfigurationKeyRemovalDetectedNotification, userInfo: [
                            KDERemoteConfigurationKeyKey: element,
                            KDERemoteConfigurationOldValueKey: self[element] ?? ""
                            ])
                        return true
                    }
                    return false
                })

                //Caching & saving date
                self.configuration = configuration
                self.configurationDate = NSDate()
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
        self.postNotificationNamed(KDERemoteConfigurationDidEndCycleNotification)
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
