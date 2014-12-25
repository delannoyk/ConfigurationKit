//
//  KDEFileDownloader.swift
//  KDEConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

private let kKDEFileDownloaderDefaultRefreshInterval = NSTimeInterval(2 * 60 * 60)

internal typealias KDEFileDownloaderBeginBlock = () -> NSURLRequest
internal typealias KDEFileDownloaderCompletion = (NSData?, NSHTTPURLResponse?, NSError?) -> Void

internal class KDEFileDownloader: NSObject {
    private var timer: NSTimer?
    private var hasStart = false
    private var lock = NSLock()
    private var dispatchQueue = dispatch_queue_create("kde_file_downloader", 0)

    // MARK: - Configuration
    ////////////////////////////////////////////////////////////////////////////

    var refreshWhenEnteringForeground: Bool = false {
        didSet {
            if oldValue != self.refreshWhenEnteringForeground {
                if self.refreshWhenEnteringForeground {
                    NSNotificationCenter.defaultCenter().addObserver(self,
                        selector: "appWillEnterForeground:",
                        name: UIApplicationWillEnterForegroundNotification,
                        object: nil)
                }
                else {
                    NSNotificationCenter.defaultCenter().removeObserver(self,
                        name: UIApplicationWillEnterForegroundNotification,
                        object: nil)
                }
            }
        }
    }

    var refreshOnIntervalBasis: Bool = false {
        didSet {
            if oldValue != self.refreshOnIntervalBasis {
                self.createTimerIfNecessary()
            }
        }
    }

    var refreshInterval: NSTimeInterval {
        didSet {
            if self.refreshOnIntervalBasis {
                self.refreshOnIntervalBasis = false
                self.refreshOnIntervalBasis = true
            }
        }
    }
    
    var beginBlock: KDEFileDownloaderBeginBlock
    var completionBlock: KDEFileDownloaderCompletion? = nil

    ////////////////////////////////////////////////////////////////////////////


    // MARK: - Initialization
    ////////////////////////////////////////////////////////////////////////////

    init(refreshWhenEnteringForeground: Bool = true, refreshOnIntervalBasis: Bool = true,
        refreshInterval: NSTimeInterval = kKDEFileDownloaderDefaultRefreshInterval,
        beginBlock: KDEFileDownloaderBeginBlock) {
            self.refreshWhenEnteringForeground = refreshWhenEnteringForeground
            self.refreshOnIntervalBasis = refreshOnIntervalBasis
            self.refreshInterval = refreshInterval
            self.beginBlock = beginBlock
            super.init()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: - Start/Stop
    ////////////////////////////////////////////////////////////////////////////

    func start() {
        if !self.hasStart {
            self.hasStart = true

            //Initial mandatory refresh
            self.refresh()
        }
    }

    func stop() {
        if self.hasStart {
            self.hasStart = false
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: - Refresh invocators
    ////////////////////////////////////////////////////////////////////////////

    func timerTicker(NSTimer) {
        self.refresh()
    }

    func appWillEnterForeground(NSNotification) {
        if self.hasStart {
            self.refresh()
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: - Refresh
    ////////////////////////////////////////////////////////////////////////////

    private func refresh() {
        //If tryLock fails that means a refresh is already being performed
        if self.lock.tryLock() {
            dispatch_async(self.dispatchQueue, { () -> Void in
                var request = self.beginBlock()

                //Getting the data
                var error: NSError? = nil
                var response: NSURLResponse? = nil
                var data = NSURLConnection.sendSynchronousRequest(request,
                    returningResponse: &response,
                    error: &error)

                //Calling completion
                if let completionBlock = self.completionBlock {
                    completionBlock(data, response as? NSHTTPURLResponse, error)
                }

                //Planning next cycle
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.createTimerIfNecessary()
                    self.lock.unlock()
                })
            })
        }
        else {
            //TODO:
            // We will only take care of this situation if last refresh failed
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: - Timer
    ////////////////////////////////////////////////////////////////////////////

    private func createTimerIfNecessary() {
        self.invalidateTimer()

        if refreshOnIntervalBasis && self.hasStart {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(self.refreshInterval,
                target: self,
                selector: "timerTicked:",
                userInfo: nil,
                repeats: false)
        }
    }

    private func invalidateTimer() {
        if let timer = self.timer {
            timer.invalidate()
        }
        self.timer = nil
    }

    ////////////////////////////////////////////////////////////////////////////
}
