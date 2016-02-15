//
//  Downloader.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright © 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `Downloader` has the responsability to download data from a given
 *  `NSURLRequest`.
 */
protocol Downloader {
    /// A boolean value indicating whether the `Downloader` already has a
    /// pending request that hasn't been fulfilled yet.
    var hasPendingRequest: Bool { get }

    /**
     Downloads data from an `NSURLRequest` and calls the completion back
     when data is ready.

     - parameter request:    The request to download data from.
     - parameter completion: The completion to call when data is ready.
     */
    func downloadData(request: NSURLRequest, completion: (NSData?, ErrorType?) -> Void)
}

/**
 *  An `URLSessionDownloader` is an implementation of a Downloader based
 *  on `NSURLSession`.
 */
class URLSessionDownloader: Downloader {
    /**
     The possible self-generated errors.

     - Cancelled: The operation was cancelled.
     */
    enum URLSessionDownloaderError: ErrorType {
        case Cancelled
    }

    /// The session to use.
    let session: NSURLSession

    /// The response queue.
    let responseQueue: dispatch_queue_t

    /// The current task.
    var currentTask: NSURLSessionDataTask?

    /// The current task associated completion.
    var currentTaskCompletion: ((NSData?, ErrorType?) -> Void)?

    /**
     Initializes an `URLSessionDownloader`.

     - parameter session:       The session to use.
     - parameter responseQueue: The response queue.

     - returns: An initialized `URLSessionDownloader`.
     */
    init(session: NSURLSession = NSURLSession.sharedSession(), responseQueue: dispatch_queue_t) {
        self.session = session
        self.responseQueue = responseQueue
    }

    /// A boolean value indicating whether the `Downloader` already has a
    /// pending request that hasn't been fulfilled yet.
    var hasPendingRequest: Bool {
        return currentTask != nil
    }

    /**
     Downloads data from an `NSURLRequest` and calls the completion back
     when data is ready.
     
     - note: If another request is currently being performed, it will be cancelled
        and a new one will start.

     - parameter request:    The request to download data from.
     - parameter completion: The completion to call when data is ready.
     */
    func downloadData(request: NSURLRequest, completion: (NSData?, ErrorType?) -> Void) {
        if let currentTask = currentTask, currentTaskCompletion = currentTaskCompletion {
            currentTask.cancel()
            currentTaskCompletion(nil, URLSessionDownloaderError.Cancelled)
        }

        let task = session.dataTaskWithRequest(request) { [weak self] data, response, error in
            if let strongSelf = self {
                strongSelf.currentTask = nil
                dispatch_sync(strongSelf.responseQueue) {
                    completion(data, error)
                }
            }
        }
        currentTask = task
        task.resume()
    }
}
