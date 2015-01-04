//
//  KDERemoteConfiguration.swift
//  KDERemoteConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

let KDERemoteConfigurationWillStartNewCycleNotification = "KDERemoteConfigurationWillStartNewCycleNotification"
let KDERemoteConfigurationDidEndCycleNotification = "KDERemoteConfigurationDidEndCycleNotification"

let KDERemoteConfigurationNewKeyDetectedNotification = "KDERemoteConfigurationNewKeyDetectedNotification"
let KDERemoteConfigurationValueChangedNotification = "KDERemoteConfigurationValueChangedNotification"
let KDERemoteConfigurationKeyRemovalDetectedNotification = "KDERemoteConfigurationKeyRemovalDetectedNotification"

let KDERemoteConfigurationKeyKey = "KDERemoteConfigurationKeyKey"
let KDERemoteConfigurationNewValueKey = "KDERemoteConfigurationNewValueKey"
let KDERemoteConfigurationOldValueKey = "KDERemoteConfigurationOldValueKey"

public class KDERemoteConfiguration: NSObject {
    private var URLBuilder: KDEURLBuilder
    private var parser: KDERemoteConfigurationParser

    private lazy var fileDownloader: KDEFileDownloader = {
        var downloader = KDEFileDownloader(beginBlock: self.fileDownloaderWillStart)
        downloader.completionBlock = self.fileDownloaderCompletedWithData
        return downloader
    }()

    private(set) var configurationDate: NSDate?
    private(set) var lastCycleDate: NSDate?
    private(set) var lastCycleError: NSError?

    private var configuration: [String: String]

    // MARK: - Initialization & Deinitialization
    ////////////////////////////////////////////////////////////////////////////

    public convenience init(URL: NSURL, parser: KDERemoteConfigurationParser) {
        self.init(URLRequest: NSURLRequest(URL: URL), parser: parser)
    }

    public convenience init(URLRequest: NSURLRequest, parser: KDERemoteConfigurationParser) {
        self.init(URLBuilder: KDESimpleURLBuilder(URLRequest: URLRequest), parser: parser)
    }

    public init(URLBuilder: KDEURLBuilder, parser: KDERemoteConfigurationParser) {
        self.URLBuilder = URLBuilder
        self.parser = parser
        self.configuration = [:]
        super.init()

        self.fileDownloader.start()
    }


    deinit {
        self.fileDownloader.stop()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: - Subscript & Object for key
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


    // MARK: - KDEFileDownloader handler
    ////////////////////////////////////////////////////////////////////////////

    private func fileDownloaderWillStart() -> NSURLRequest {
        self.postNotificationNamed(KDERemoteConfigurationWillStartNewCycleNotification)
        return self.URLBuilder.URLRequest()
    }

    private func fileDownloaderCompletedWithData(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) {
        if let data = data {
            //1. Parsing
            var parsingResult = self.parser.parseData(data)
            if let configuration = parsingResult.configuration {
                //2. Analyzing changes & new values
                for (key, value) in configuration {
                    var existingValue = self[key]
                    self.configuration[key] = value

                    if let existingValue = existingValue {
                        if existingValue != value {
                            self.postNotificationNamed(KDERemoteConfigurationValueChangedNotification,
                                userInfo: [
                                    KDERemoteConfigurationKeyKey: key,
                                    KDERemoteConfigurationOldValueKey: existingValue,
                                    KDERemoteConfigurationNewValueKey: value
                                ])
                        }
                    }
                    else {
                        self.postNotificationNamed(KDERemoteConfigurationNewKeyDetectedNotification,
                            userInfo: [
                                KDERemoteConfigurationKeyKey: key,
                                KDERemoteConfigurationNewValueKey: value
                            ])
                    }
                }

                //3. Analyzing removal
                var newKeys = configuration.keys.array
                var removedKeys = self.configuration.keys.array.filter({element in
                    return !contains(newKeys, element)
                })
                for key in removedKeys {
                    if let value = self.configuration[key] {
                        self.configuration.removeValueForKey(key)

                        self.postNotificationNamed(KDERemoteConfigurationKeyRemovalDetectedNotification,
                            userInfo: [
                                KDERemoteConfigurationKeyKey: key,
                                KDERemoteConfigurationOldValueKey: value
                            ])
                    }
                    //The else case should not happen anytime
                }

                //4. Caching
                self.configuration = configuration

                //5. Saving last cycle date
                self.configurationDate = NSDate()
            }
            else {
                self.lastCycleError = parsingResult.error
            }
        }
        else {
            self.lastCycleError = error
        }

        self.lastCycleDate = NSDate()
        self.postNotificationNamed(KDERemoteConfigurationDidEndCycleNotification)
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: - Notification
    ////////////////////////////////////////////////////////////////////////////

    private func postNotificationNamed(name: String, userInfo: [NSObject: AnyObject]? = nil) {
        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
            var note = NSNotification(name: name, object: self, userInfo: userInfo)
            NSNotificationCenter.defaultCenter().postNotification(note)
        })
    }

    ////////////////////////////////////////////////////////////////////////////
}
