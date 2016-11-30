//
//  Downloader.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright © 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `Downloader` has the responsability to download data from a given `NSURLRequest`.
 */
protocol Downloader {
    /// A boolean value indicating whether the `Downloader` already has a pending request that
    /// hasn't been fulfilled yet.
    var hasPendingRequest: Bool { get }

    /**
     Downloads data from an `NSURLRequest` and calls the completion back when data is ready.

     - parameter request:    The request to download data from.
     - parameter completion: The completion to call when data is ready.
     */
    func downloadData(with request: URLRequest, completion: @escaping (Data?, Error?) -> Void)
}

/**
 *  An `URLSessionDownloader` is an implementation of a Downloader based on `NSURLSession`.
 */
class URLSessionDownloader: Downloader {
    /// The session to use.
    let session: URLSession

    /// The response queue.
    let responseQueue: DispatchQueue

    /// The current task.
    var currentTask: URLSessionDataTask?

    /**
     Initializes an `URLSessionDownloader`.

     - parameter session:       The session to use.
     - parameter responseQueue: The response queue.
     */
    init(session: URLSession = URLSession.shared, responseQueue: DispatchQueue) {
        self.session = session
        self.responseQueue = responseQueue
    }

    /// A boolean value indicating whether the `Downloader` already has a pending request that
    /// hasn't been fulfilled yet.
    var hasPendingRequest: Bool {
        return currentTask != nil
    }

    /**
     Downloads data from an `NSURLRequest` and calls the completion back when data is ready.

     - note: If another request is currently being performed, it will be cancelled and a new one
         will start.

     - parameter request:    The request to download data from.
     - parameter completion: The completion to call when data is ready.
     */
    func downloadData(with request: URLRequest, completion: @escaping (Data?, Error?) -> Void) {
        if let currentTask = currentTask {
            currentTask.cancel()
        }

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            self?.currentTask = nil
            self?.responseQueue.sync {
                completion(data, error)
            }
        }
        currentTask = task
        task.resume()
    }
}
