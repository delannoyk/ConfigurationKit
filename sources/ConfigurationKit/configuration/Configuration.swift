//
//  Configuration.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright © 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  `ConfigurationEventListener` is an internal implementation of `EventListener` so that we don't
 *  have to make the implementation public.
 */
private class ConfigurationEventListener: EventListener {
    /// The real event listener
    weak var realEventListener: InternalEventListener?

    /**
     Called when an event occurs.
     */
    func onEvent() {
        realEventListener?.onEvent()
    }
}

/**
 *  Implementing this protocol makes your class eligible to Configuration alerts about cycles and
 *  changes.
 */
public protocol ConfigurationDelegate: class {
    /**
     Lets you know that the configuration will begin a new cycle because an EventProducer fired.

     - parameter configuration: The configuration.
     */
    func configurationWillBeginCycle(configuration: Configuration)

    /**
     Alerts that the configuration found a change after downloading and parsing a new configuration
     file.

     - parameter configuration: The configuration.
     - parameter change:        The change that has been detected.
     */
    func configuration(configuration: Configuration, didDetectChange change: Change<String, String>)

    /**
     Lets you know that the configuration did end the current cycle.

     - parameter configuration: The configuration.
     - parameter error:         The error that happened if any.
     */
    func configuration(configuration: Configuration, didEndCycleWithError error: ErrorType?)
}

/**
 *  This is a wrapper around ConfigurationDelegate to be weak.
 */
private final class WeakDelegate {
    /// The delegate.
    weak var delegate: ConfigurationDelegate?

    /**
     Initializes a new `WeakDelegate` from a delegate.

     - parameter delegate: The delegate.
     */
    init(_ delegate: ConfigurationDelegate) {
        self.delegate = delegate
    }
}

/**
 *  <#Description#>
 */
public final class Configuration {
    /// The fake event listener
    private let eventListener = ConfigurationEventListener()

    /// The lock used to access configuration.
    private let configurationMutex = NSLock()

    /// The lock used to prevent multiple events to override each other.
    private let cycleMutex = NSLock()

    /// The queue used to perform cycles.
    private let cycleQueue = dispatch_queue_create("be.delannoyk.configurationkit", nil)

    /// The delegates.
    private var delegates = [WeakDelegate]()

    /// The current configuration.
    private var configuration: [String: String]

    /// The encryptor used to decrypt downloaded file.
    private let downloadEncryptor: Encryptor?

    /// The encryptor used to encrypt/decrypt the configuration cached.
    private let cacheEncryptor: Encryptor?

    /// The cacher to use to make the configuration persistent.
    private let cacher: Cacher?

    /// The builder used to create an URL when needed.
    private let urlBuilder: URLBuilder

    /// The parser used to parse a configuration file.
    private let parser: Parser

    /// The list of event producers that generate events when a new cycle should be started.
    private let eventProducers: [EventProducer]

    /// The downloader used to download a configuration file.
    internal var downloader: Downloader

    /// Let's you specify whether an new event should cancel any current request to be sure you
    /// always have the latest version of the configuration.
    public var newEventCancelCurrentOne: Bool

    /// The date of the last refresh of configuration.
    public private(set) var configurationDate: NSDate

    /// The date when the last cycle happened.
    public private(set) var lastCycleDate: NSDate?

    /// The error that happened at last cycle if any.
    public private(set) var lastCycleError: ErrorType?


    /// The Cache information to use.
    public typealias CacheInitializer = (Cacher?, Encryptor?)

    /// The Download information to use.
    public typealias DownloadInitializer = (URLBuilder, Parser, Encryptor?)


    /**
     Initializes a `Configuration` with every information needed. This one takes an initial
     configuration as arguments.

     - parameter downloadInitializer:  The information to use to download file from a remote server.
     - parameter cacheInitializer:     The information to use to cache downloaded files on the
         device to always keep the latest version.
     - parameter cycleGenerators:      The list of event producers that will generate a new refresh
         cycle.
     - parameter newEventCancelCurrentOne: States if a new event should cancel any current refresh
         request or be dropped.
     - parameter initialConfiguration: The initial configuration to use.
     */
    public init(downloadInitializer: DownloadInitializer,
        cacheInitializer: CacheInitializer? = nil,
        cycleGenerators: [EventProducer],
        newEventCancelCurrentOne: Bool = false,
        initialConfiguration: [String: String]) {
            configuration = initialConfiguration
            downloadEncryptor = downloadInitializer.2
            cacheEncryptor = cacheInitializer?.1
            cacher = cacheInitializer?.0
            urlBuilder = downloadInitializer.0
            parser = downloadInitializer.1
            eventProducers = cycleGenerators
            downloader = URLSessionDownloader(responseQueue: cycleQueue)
            self.newEventCancelCurrentOne = newEventCancelCurrentOne
            configurationDate = NSDate()

            commonInit()
    }

    /**
     Initializes a `Configuration` with every information needed. This one takes
     the path to the initial configuration file.

     - parameter downloadInitializer:          The information to use to download file from a remote
         server.
     - parameter cacheInitializer:             The information to use to cache downloaded files on
         the device to always keep the latest version.
     - parameter cycleGenerators:              The list of event producers that will generate a new
         refresh cycle.
     - parameter newEventCancelCurrentOne:     States if a new event should cancel any current
         refresh request or be dropped.
     - parameter initialConfigurationFilePath: The path to the initial configuration file. It will
         be treated as a remote file (decrypted and parsed).
     */
    public init(downloadInitializer: DownloadInitializer,
        cacheInitializer: CacheInitializer? = nil,
        cycleGenerators: [EventProducer],
        newEventCancelCurrentOne: Bool = false,
        initialConfigurationFilePath: String) {
            configuration = [:]//TODO: read the configuration from the file path
            downloadEncryptor = downloadInitializer.2
            cacheEncryptor = cacheInitializer?.1
            cacher = cacheInitializer?.0
            urlBuilder = downloadInitializer.0
            parser = downloadInitializer.1
            eventProducers = cycleGenerators
            downloader = URLSessionDownloader(responseQueue: cycleQueue)
            self.newEventCancelCurrentOne = newEventCancelCurrentOne
            configurationDate = NSDate()//TODO: read the attributes from the file path

            commonInit()
    }

    /**
     Performs everything the initializers has in common.
     */
    private func commonInit() {
        //Initializing from cache if possible
        if let confData = cacher?.dataAtKey(Cache.Configuration.key) {
            let data = cacheEncryptor?.decryptedData(confData) ?? confData
            if let cached = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: String] {
                    configuration = cached
            }
        }

        if let dateData = cacher?.dataAtKey(Cache.Date.key) {
            let data = cacheEncryptor?.decryptedData(dateData) ?? dateData
            if let cached = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDate {
                    configurationDate = cached
            }
        }

        //Configuring eventProducers
        eventListener.realEventListener = self
        eventProducers.forEach {
            $0.eventListener = eventListener
            $0.startProducingEvents()
        }
    }

    /**
     Stops event producers.
     */
    deinit {
        eventProducers.forEach {
            $0.eventListener = nil
            $0.stopProducingEvents()
        }
    }


    /**
     Returns The value associated with `key`, or nil if no value is associated with `key`.

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
        case Configuration
        case Date

        /// The key for the data to be cached at.
        var key: String {
            switch self {
            case .Configuration:
                return "configuration"
            case .Date:
                return "date"
            }
        }
    }
}

extension Configuration: InternalEventListener {
    /**
     Called upon event. This will generate a new cycle if possible and handle everything.
     */
    func onEvent() {
        guard !downloader.hasPendingRequest || newEventCancelCurrentOne else {
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
                    } else if let error = error {
                        self?.handleError(error)
                    } else {
                        //We didn't have any data nor error.
                        //Nothing changes then...
                    }

                    if let strongSelf = self {
                        strongSelf.cycleMutex.unlock()
                        strongSelf.lastCycleDate = NSDate()

                        strongSelf.delegates.forEach {
                            $0.delegate?.configuration(strongSelf,
                                didEndCycleWithError: strongSelf.lastCycleError)
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
        configurationDate = NSDate()
        configurationMutex.unlock()

        //Fire delegate events
        differences.forEach { change in
            delegates.forEach {
                $0.delegate?.configuration(self, didDetectChange: change)
            }
        }

        //Let's cache
        let data = NSKeyedArchiver.archivedDataWithRootObject(configurationDate)
        let dateData = cacheEncryptor?.encryptedData(data) ?? data

        if differences.count > 0 {
            let data = NSKeyedArchiver.archivedDataWithRootObject(configuration)
            let configurationData = cacheEncryptor?.encryptedData(data) ?? data

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
