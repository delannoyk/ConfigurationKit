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

//let KDERemoteConfigurationNewKeyDetectedNotification = ""
//let KDERemoteConfigurationKeyRemovalDetectedNotification = ""

public class KDERemoteConfiguration: NSObject {
    private var URLBuilder: KDEURLBuilder
    private var parser: KDERemoteConfigurationParser

    private lazy var fileDownloader: KDEFileDownloader = {
        return KDEFileDownloader(beginBlock: self.fileDownloaderWillStart)
    }()

    private var configuration: [String: String]
    private(set) var configurationDate: NSDate?
    private(set) var lastCycleDate: NSDate?
    private(set) var lastCycleError: NSError?

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

        self.fileDownloader.completionBlock = self.fileDownloaderCompletedWithData
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
                //2. Analyzing changes
                for (key, value) in configuration {
                    var existingValue = self[key]
                    self.configuration[key] = value

                    if let existingValue = existingValue {
                        if existingValue != value {
                            //TODO: Notification value changed
                        }
                    }
                    else {
                        //TODO: Notification new key detected
                    }

                }

                //3. Caching
                self.configuration = configuration

                //4. Saving last cycle date
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
