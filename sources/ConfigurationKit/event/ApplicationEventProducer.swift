//
//  ApplicationEventProducer.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 11/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import UIKit

/**
 *  A `EventProducer` that listens to when application enters in foreground and generates an
 *  event from that.
 */
public class ApplicationEventProducer: NSObject, EventProducer {
    /// A boolean value indicating whether we're already generating events or not.
    private var started = false

    /// The event listener.
    public weak var eventListener: EventListener?

    /**
     Stops producing events on deinit.
     */
    deinit {
        stopProducingEvents()
    }

    /**
     Listens to application notifications and generates events each time one of these
     notification gets fired.
     */
    public func startProducingEvents() {
        guard !started else {
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: UIApplication.shared)
        started = true
    }

    /**
     Stops listening to registered notifications.
     */
    public func stopProducingEvents() {
        guard started else {
            return
        }

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: UIApplication.shared)
        started = false
    }

    /**
     Method that gets called when `UIApplicationWillEnterForegroundNotification` is fired.

     - parameter note: The notification.
     */
    @objc private func applicationWillEnterForeground(_ note: Notification) {
        eventListener?.onEvent()
    }
}
