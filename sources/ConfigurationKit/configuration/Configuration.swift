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
    func configurationWillBeginCycle(_ configuration: Configuration)

    /**
     Alerts that the configuration found a change after downloading and parsing a new configuration
     file.

     - parameter configuration: The configuration.
     - parameter change:        The change that has been detected.
     */
    func configuration(_ configuration: Configuration, didDetectChange change: Change<String, String>)

    /**
     Lets you know that the configuration did end the current cycle.

     - parameter configuration: The configuration.
     - parameter error:         The error that happened if any.
     */
    func configuration(_ configuration: Configuration, didEndCycleWithError error: Error?)
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
public class Configuration {
    private enum InitializationError: Error {
        case fileDoesNotExist
    }

    /// The fake event listener
    private let eventListener = ConfigurationEventListener()

    /// The lock used to access configuration.
    fileprivate let configurationMutex = NSLock()

    /// The lock used to prevent multiple events to override each other.
    fileprivate let cycleMutex = NSLock()

    /// The queue used to perform cycles.
    fileprivate let cycleQueue = DispatchQueue(label: "be.delannoyk.configurationkit")

    /// The delegates.
    private var weakDelegates = [WeakDelegate]()

    /// The current configuration.
    fileprivate var configuration: [String: String]

    /// The encryptor used to decrypt downloaded file.
    fileprivate let downloadEncryptor: Encryptor?

    /// The encryptor used to encrypt/decrypt the configuration cached.
    fileprivate let cacheEncryptor: Encryptor?

    /// The cacher to use to make the configuration persistent.
    fileprivate let cacher: Cacher?

    /// The builder used to create an URL when needed.
    fileprivate let urlRequestBuilder: URLRequestBuilder

    /// The parser used to parse a configuration file.
    fileprivate let parser: Parser

    /// The list of event producers that generate events when a new cycle should be started.
    private let eventProducers: [EventProducer]

    /// The downloader used to download a configuration file.
    var downloader: Downloader

    /// Let's you specify whether an new event should cancel any current request to be sure you
    /// always have the latest version of the configuration.
    public var newEventCancelCurrentOne: Bool

    /// The date of the last refresh of configuration.
    public fileprivate(set) final var configurationDate: Date

    /// The date when the last cycle happened.
    public fileprivate(set) final var lastCycleDate: Date?

    /// The error that happened at last cycle if any.
    public fileprivate(set) final var lastCycleError: Error?


    /// The Cache information to use.
    public typealias CacheInitializer = (Cacher?, Encryptor?)

    /// The Download information to use.
    public typealias DownloadInitializer = (URLRequestBuilder, Parser, Encryptor?)


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
            urlRequestBuilder = downloadInitializer.0
            parser = downloadInitializer.1
            eventProducers = cycleGenerators
            downloader = URLSessionDownloader(responseQueue: cycleQueue)
            self.newEventCancelCurrentOne = newEventCancelCurrentOne
            configurationDate = Date()

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
    public convenience init(downloadInitializer: DownloadInitializer,
        cacheInitializer: CacheInitializer? = nil,
        cycleGenerators: [EventProducer],
        newEventCancelCurrentOne: Bool = false,
        initialConfigurationFilePath: String) {
            self.init(downloadInitializer: downloadInitializer,
                cacheInitializer: cacheInitializer,
                cycleGenerators: cycleGenerators,
                newEventCancelCurrentOne: newEventCancelCurrentOne,
                initialConfigurationFilePath: initialConfigurationFilePath,
                fileManager: Foundation.FileManager.default)
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
     - parameter fileManager:                  The file manager used to get content of the file.
     */
    init(downloadInitializer: DownloadInitializer,
        cacheInitializer: CacheInitializer? = nil,
        cycleGenerators: [EventProducer],
        newEventCancelCurrentOne: Bool = false,
        initialConfigurationFilePath: String,
        fileManager: FileManager) {
            downloadEncryptor = downloadInitializer.2
            cacheEncryptor = cacheInitializer?.1
            cacher = cacheInitializer?.0
            urlRequestBuilder = downloadInitializer.0
            parser = downloadInitializer.1
            eventProducers = cycleGenerators
            downloader = URLSessionDownloader(responseQueue: cycleQueue)
            self.newEventCancelCurrentOne = newEventCancelCurrentOne

            configuration = [:]
            configurationDate = Date()

            //FIXME: I hate to use `!`.
            if cacher == nil || !cacher!.hasData(at: Cache.configuration.key) {
                do {
                    let url = URL(fileURLWithPath: initialConfigurationFilePath)
                    guard let data = fileManager.data(at: url) else {
                        throw InitializationError.fileDoesNotExist
                    }

                    let decrypted = downloadEncryptor?.decrypted(data) ?? data
                    configuration = try parser.parse(decrypted)

                    let attr = try fileManager.attributesOfItem(atPath: initialConfigurationFilePath)
                    configurationDate = (attr[.modificationDate] as? Date) ?? Date()
                } catch { }
            }

            commonInit()
    }

    /**
     Performs everything the initializers has in common.
     */
    private func commonInit() {
        //Initializing from cache if possible
        if let confData = cacher?.data(at: Cache.configuration.key) {
            let data = cacheEncryptor?.decrypted(confData) ?? confData
            if let cached = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: String] {
                configuration = cached
            }
        }

        if let dateData = cacher?.data(at: Cache.date.key) {
            let data = cacheEncryptor?.decrypted(dateData) ?? dateData
            if let cached = NSKeyedUnarchiver.unarchiveObject(with: data) as? Date {
                configurationDate = cached
            }
        }

        //Configuring eventProducers
        eventListener.realEventListener = self
        eventProducers.forEach {
            $0.eventListener = eventListener
            $0.startProducingEvents()
        }
        
        //Starting initial loading
        onEvent()
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
    public final subscript(key: String) -> String? {
        configurationMutex.lock()
        let value = configuration[key]
        configurationMutex.unlock()
        return value
    }


    /**
     Register a delegate for it to receive callbacks.

     - parameter delegate: The delegate.
     */
    public final func registerDelegate(_ delegate: ConfigurationDelegate) {
        weakDelegates.append(WeakDelegate(delegate))
    }

    /**
     Unregisters a delegate.

     - parameter delegate: The delegate.
     */
    public final func unregisterDelegate(_ delegate: ConfigurationDelegate) {
        weakDelegates = weakDelegates.filter {
            return !($0.delegate === delegate || $0.delegate == nil)
        }
    }

    /// The registered delegates.
    public final var delegates: [ConfigurationDelegate] {
        return weakDelegates.compactMap { $0.delegate }
    }


    /**
     Elements that will get cached if possible.

     - Configuration: The configuration.
     - Date:          The last successful configuration refresh date.
     */
    private enum Cache {
        case configuration
        case date

        /// The key for the data to be cached at.
        var key: String {
            switch self {
            case .configuration:
                return "configuration"
            case .date:
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
            $0.configurationWillBeginCycle(self)
        }

        cycleQueue.async { [weak self] in
            if let strongSelf = self {
                strongSelf.cycleMutex.lock()

                let request = strongSelf.urlRequestBuilder.urlRequest()
                strongSelf.downloader.downloadData(with: request) { data, error in
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
                        strongSelf.lastCycleDate = Date()

                        strongSelf.delegates.forEach {
                            $0.configuration(strongSelf,
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
    func handleData(_ data: Data) throws {
        let decryptedData = downloadEncryptor?.decrypted(data) ?? data
        let newConfiguration = try parser.parse(decryptedData)
        let differences = configuration.delta(newConfiguration)

        configurationMutex.lock()
        configuration = newConfiguration
        configurationDate = Date()
        configurationMutex.unlock()

        //Fire delegate events
        differences.forEach { change in
            delegates.forEach {
                $0.configuration(self, didDetectChange: change)
            }
        }

        //Let's cache
        let data = NSKeyedArchiver.archivedData(withRootObject: configurationDate)
        let dateData = cacheEncryptor?.encrypted(data) ?? data

        if differences.count > 0 {
            let data = NSKeyedArchiver.archivedData(withRootObject: configuration)
            let configurationData = cacheEncryptor?.encrypted(data) ?? data

            try cacher?.store(configurationData, at: "configuration")
        }
        try cacher?.store(dateData, at: "configuration_date")

        lastCycleError = nil
    }

    /**
     Handles the cycle error.

     - parameter error: The error.
     */
    func handleError(_ error: Error) {
        lastCycleError = error
    }
}
