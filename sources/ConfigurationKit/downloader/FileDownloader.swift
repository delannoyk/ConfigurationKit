//
//  FileDownloader.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

private let kFileDownloaderDefaultRefreshInterval = NSTimeInterval(2 * 60 * 60)

internal final class FileDownloader: NSObject {
    private let lock = NSLock()
    private let dispatchQueue = dispatch_queue_create("file_downloader", nil)

    private var timer: NSTimer?
    private var hasStart = false

    internal typealias FileDownloaderOnBegin = () -> NSURLRequest?
    internal typealias FileDownloaderOnCompletion = (NSData?, NSHTTPURLResponse?, NSError?) -> Void

    // MARK: Configuration
    ////////////////////////////////////////////////////////////////////////////

    var refreshWhenEnteringForeground = false {
        didSet {
            if oldValue != refreshWhenEnteringForeground {
                didUpdateRefreshWhenEnteringForeground()
            }
        }
    }

    var refreshOnIntervalBasis = false {
        didSet {
            if oldValue != refreshOnIntervalBasis {
                createTimerIfNecessary()
            }
        }
    }

    var refreshInterval = kFileDownloaderDefaultRefreshInterval {
        didSet {
            if refreshOnIntervalBasis {
                createTimerIfNecessary()
            }
        }
    }

    var onRefreshBegin: FileDownloaderOnBegin

    var onRefreshComplete: FileDownloaderOnCompletion? = nil

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    init(refreshWhenEnteringForeground: Bool = true, refreshOnIntervalBasis: Bool = true,
        refreshInterval: NSTimeInterval = kFileDownloaderDefaultRefreshInterval,
        beginBlock: FileDownloaderOnBegin) {
            self.refreshWhenEnteringForeground = refreshWhenEnteringForeground
            self.refreshOnIntervalBasis = refreshOnIntervalBasis
            self.refreshInterval = refreshInterval
            self.onRefreshBegin = beginBlock
            super.init()

            didUpdateRefreshWhenEnteringForeground()
            createTimerIfNecessary()
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
        if !hasStart {
            hasStart = true

            //Initial mandatory refresh
            refresh()
        }
    }

    func stop() {
        if hasStart {
            hasStart = false
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Refresh invocators
    ////////////////////////////////////////////////////////////////////////////

    func timerTicked(NSTimer) {
        refresh()
    }

    func appWillEnterForeground(NSNotification) {
        if hasStart {
            refresh()
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Refresh
    ////////////////////////////////////////////////////////////////////////////

    private func refresh() {
        //If tryLock fails that means a refresh is already being performed
        if lock.tryLock() {
            dispatch_async(dispatchQueue, { () -> Void in
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
        invalidateTimer()

        if refreshOnIntervalBasis && hasStart {
            timer = NSTimer.scheduledTimerWithTimeInterval(refreshInterval,
                target: self,
                selector: "timerTicked:",
                userInfo: nil,
                repeats: false)
        }
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    ////////////////////////////////////////////////////////////////////////////
}
