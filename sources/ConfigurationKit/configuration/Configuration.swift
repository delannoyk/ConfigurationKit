//
//  Configuration.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright © 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  <#Description#>
 */
public protocol ConfigurationDelegate: class {
    func configurationWillBeginCycle(configuration: Configuration)
    func configuration(configuration: Configuration, didDetectChange: Change<String, String>)
    func configuration(configuration: Configuration, didEndCycleWithError error: ErrorType?)
}

/**
 *  <#Description#>
 */
private final class WeakDelegate {
    /// <#Description#>
    weak var delegate: ConfigurationDelegate?

    /**
     <#Description#>

     - parameter delegate: <#value description#>

     - returns: <#return value description#>
     */
    init(_ delegate: ConfigurationDelegate) {
        self.delegate = delegate
    }
}

/**
 *  <#Description#>
 */
public final class Configuration {
    //private let eventListener = InternalEventListener()

    /// <#Description#>
    private let configurationMutex = NSLock()

    /// <#Description#>
    private let cycleMutex = NSLock()

    /// <#Description#>
    private let cycleQueue = dispatch_queue_create("be.delannoyk.configurationkit", nil)

    /// <#Description#>
    private var delegates = [WeakDelegate]()

    /// <#Description#>
    private var configuration: [String: String]

    /// <#Description#>
    private let downloadEncryptor: Encryptor?

    /// <#Description#>
    private let cacheEncryptor: Encryptor?

    /// <#Description#>
    private let cacher: Cacher?

    /// <#Description#>
    private let urlBuilder: URLBuilder

    /// <#Description#>
    private let parser: Parser

    /// <#Description#>
    private let eventProducers: [EventProducer]

    /// <#Description#>
    internal var downloader: Downloader

    /// <#Description#>
    private let bundleConfigurationFilePath: String?

    /// <#Description#>
    public var cancelCurrentRequestWhenEventOccursBeforeEnd = true

    /// <#Description#>
    public private(set) var configurationDate: NSDate?

    /// <#Description#>
    public private(set) var lastCycleDate: NSDate?

    /// <#Description#>
    public private(set) var lastCycleError: ErrorType?

    public init() {
        //TODO: this initializer is just for compilation purpose. We need a correct one.
        configuration = [:]
        downloadEncryptor = nil
        cacheEncryptor = nil
        cacher = nil
        urlBuilder = SimpleURLBuilder(URL: NSURL())
        parser = FlatJSONParser()
        eventProducers = []
        downloader = URLSessionDownloader(responseQueue: cycleQueue)
        bundleConfigurationFilePath = nil

        //TODO: start event producers
    }

    deinit {
        eventProducers.forEach {
            $0.eventListener = nil
            $0.stopProducingEvents()
        }
    }

    /**
     Returns The value associated with `key`, or nil if no value
     is associated with `key`.

     - parameter key: The key for which to return the corresponding value.

     - returns: The value associated with `key`, or nil if no value is associated with `key`.
     */
    public subscript(key: String) -> String? {
        configurationMutex.lock()
        let value = configuration[key]
        configurationMutex.unlock()
        return value
    }

    /**
     Returns The value associated with `key`, or nil if no value
     is associated with `key`.

     - parameter key: The key for which to return the corresponding value.

     - returns: The value associated with `key`, or nil if no value is associated with `key`.
     */
    public func stringForKey(key: String) -> String? {
        return self[key]
    }

    /**
     Returns The value associated with `key`, or nil if no value
     is associated with `key`.

     - parameter key: The key for which to return the corresponding value.

     - returns: The value associated with `key`, or nil if no value is associated with `key`.
     */
    public func objectForKey(key: String) -> String? {
        return self[key]
    }


    /**
     Register a delegate for it to receive callbacks.

     - parameter delegate: The delegate.
     */
    public func registerDelegate(delegate: ConfigurationDelegate) {
        delegates.append(WeakDelegate(delegate))
    }

    /**
     Unregisters a delegate.

     - parameter delegate: The delegate.
     */
    public func unregisterDelegate(delegate: ConfigurationDelegate) {
        delegates = delegates.filter {
            return !($0.delegate === delegate || $0.delegate == nil)
        }
    }


    /**
     Elements that will get cached if possible.

     - Configuration: The configuration.
     - Date:          The last successful configuration refresh date.
     */
    private enum Cache {
        case Configuration([String: String])
        case Date(NSDate)

        /// The key for the data to be cached at.
        var key: String {
            switch self {
            case .Configuration:
                return "configuration"
            case .Date:
                return "date"
            }
        }

        /// The data to cache.
        var data: NSData {
            switch self {
            case .Configuration(let configuration):
                return NSKeyedArchiver.archivedDataWithRootObject(configuration)
            case .Date(let date):
                return NSKeyedArchiver.archivedDataWithRootObject(date)
            }
        }
    }
}

extension Configuration: InternalEventListener {
    /**
     Called upon event. This will generate a new cycle if possible and
     handle everything.
     */
    func onEvent() {
        guard !downloader.hasPendingRequest || cancelCurrentRequestWhenEventOccursBeforeEnd else {
            //Last request didn't complete so we drop the event.
            return
        }

        delegates.forEach {
            $0.delegate?.configurationWillBeginCycle(self)
        }

        dispatch_async(cycleQueue) { [weak self] in
            if let strongSelf = self {
                strongSelf.cycleMutex.lock()

                let request = strongSelf.urlBuilder.URLRequest()
                strongSelf.downloader.downloadData(request) { data, error in
                    if let data = data {
                        do {
                            try self?.handleData(data)
                        } catch let error {
                            self?.handleError(error)
                        }
                    }
                    else if let error = error {
                        self?.handleError(error)
                    }
                    else {
                        //We didn't have any data nor error.
                        //TODO: how do Configuration reacts to this?
                    }

                    if let strongSelf = self {
                        strongSelf.cycleMutex.unlock()
                        strongSelf.lastCycleDate = NSDate()

                        strongSelf.delegates.forEach {
                            $0.delegate?.configuration(strongSelf, didEndCycleWithError: strongSelf.lastCycleError)
                        }
                    }
                }
            }
        }
    }

    /**
     Handles the data after a download.

     - parameter data: The downloaded data.

     - throws: Rethrows cacher error if any.
     */
    func handleData(data: NSData) throws {
        let decryptedData = downloadEncryptor?.decryptedData(data) ?? data
        let newConfiguration = try parser.parseData(decryptedData)
        let differences = configuration.delta(newConfiguration)

        configurationMutex.lock()
        configuration = newConfiguration
        let now = NSDate()
        configurationDate = now
        configurationMutex.unlock()

        //Fire delegate events
        differences.forEach { change in
            delegates.forEach {
                $0.delegate?.configuration(self, didDetectChange: change)
            }
        }

        //Let's cache
        let cacheDate = Cache.Date(now)
        let dateData = cacheEncryptor?.encryptedData(cacheDate.data) ?? cacheDate.data
        if differences.count > 0 {
            let cacheConfiguration = Cache.Configuration(configuration)
            let configurationData = cacheEncryptor?.encryptedData(cacheConfiguration.data) ?? cacheConfiguration.data
            try cacher?.storeData(configurationData, atKey: "configuration")
        }
        try cacher?.storeData(dateData, atKey: "configuration_date")

        lastCycleError = nil
    }

    /**
     Handles the cycle error.

     - parameter error: The error.
     */
    func handleError(error: ErrorType) {
        lastCycleError = error
    }
}
