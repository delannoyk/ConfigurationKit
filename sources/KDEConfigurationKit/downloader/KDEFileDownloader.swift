//
//  KDEFileDownloader.swift
//  KDEConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

private let kKDEFileDownloaderDefaultRefreshInterval = NSTimeInterval(2 * 60 * 60)

internal final class KDEFileDownloader: NSObject {
    private let lock = NSLock()
    private let dispatchQueue = dispatch_queue_create("kde_file_downloader", nil)

    private var timer: NSTimer?
    private var hasStart = false

    internal typealias KDEFileDownloaderOnBegin = () -> NSURLRequest?
    internal typealias KDEFileDownloaderOnCompletion = (NSData?, NSHTTPURLResponse?, NSError?) -> Void

    // MARK: Configuration
    ////////////////////////////////////////////////////////////////////////////

    var refreshWhenEnteringForeground = false {
        didSet {
            if oldValue != self.refreshWhenEnteringForeground {
                self.didUpdateRefreshWhenEnteringForeground()
            }
        }
    }

    var refreshOnIntervalBasis = false {
        didSet {
            if oldValue != self.refreshOnIntervalBasis {
                self.createTimerIfNecessary()
            }
        }
    }

    var refreshInterval = kKDEFileDownloaderDefaultRefreshInterval {
        didSet {
            if self.refreshOnIntervalBasis {
                self.createTimerIfNecessary()
            }
        }
    }

    var onRefreshBegin: KDEFileDownloaderOnBegin

    var onRefreshComplete: KDEFileDownloaderOnCompletion? = nil

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    init(refreshWhenEnteringForeground: Bool = true, refreshOnIntervalBasis: Bool = true,
        refreshInterval: NSTimeInterval = kKDEFileDownloaderDefaultRefreshInterval,
        beginBlock: KDEFileDownloaderOnBegin) {
            self.refreshWhenEnteringForeground = refreshWhenEnteringForeground
            self.refreshOnIntervalBasis = refreshOnIntervalBasis
            self.refreshInterval = refreshInterval
            self.onRefreshBegin = beginBlock
            super.init()

            self.didUpdateRefreshWhenEnteringForeground()
            self.createTimerIfNecessary()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: State update
    ////////////////////////////////////////////////////////////////////////////

    private func didUpdateRefreshWhenEnteringForeground() {
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

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Start/Stop
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


    // MARK: Refresh invocators
    ////////////////////////////////////////////////////////////////////////////

    func timerTicked(NSTimer) {
        self.refresh()
    }

    func appWillEnterForeground(NSNotification) {
        if self.hasStart {
            self.refresh()
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Refresh
    ////////////////////////////////////////////////////////////////////////////

    private func refresh() {
        //If tryLock fails that means a refresh is already being performed
        if self.lock.tryLock() {
            dispatch_async(self.dispatchQueue, { () -> Void in
                if let URLRequest = self.onRefreshBegin() {
                    //Getting the data
                    let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(URLRequest,
                        completionHandler: {[weak self] (data, response, error) -> Void in
                            //Calling completion
                            self?.onRefreshComplete?(data, response as? NSHTTPURLResponse, error)

                            //Planning next cycle
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self?.createTimerIfNecessary()
                                self?.lock.unlock()
                            })
                        })
                    dataTask.resume()
                }
                else {
                    self.stop()
                }
            })
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Timer
    ////////////////////////////////////////////////////////////////////////////

    private func createTimerIfNecessary() {
        self.invalidateTimer()

        if self.refreshOnIntervalBasis && self.hasStart {
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
