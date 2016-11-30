//
//  TimedEventProducer.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 11/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `TimedEventProducer` generates events a specific dates and times.
 */
public class TimedEventProducer: NSObject, EventProducer {
    /// The dates.
    public fileprivate(set) var dates: [Date] {
        didSet {
            if let _ = timer {
                stopProducingEvents()
                startProducingEvents()
            }
        }
    }

    /// The timer.
    fileprivate var timer: Timer?

    /// The listener that will be alerted a new event occured.
    public weak var eventListener: EventListener?


    /**
     Initialized a `TimedEventProducer` from an array of `Date`.

     - parameter dates: The dates at which the producer should generate events.
     */
    public init(dates: [Date]) {
        self.dates = dates
            .filter { $0.timeIntervalSinceNow > 0 }
            .sorted { $0.compare($1) == .orderedAscending }

        super.init()
    }

    /**
     Stop producing events on deinit.
     */
    deinit {
        stopProducingEvents()
    }


    /**
     Tells the producer to start producing events.
     */
    public func startProducingEvents() {
        guard timer == nil else {
            return
        }

        if let date = dates.first {
            timer = Timer.scheduledTimer(timeInterval: date.timeIntervalSinceNow,
                target: WeakTarget(self),
                selector: .weakTargetSelector,
                userInfo: nil,
                repeats: false)
        }
    }

    /**
     Tells the producer to stop producing events.
     */
    public func stopProducingEvents() {
        guard let timer = timer else {
            return
        }

        timer.invalidate()
        self.timer = nil
    }
}

extension TimedEventProducer: WeakTargetDelegate {
    /**
     Method that gets called when the timer ticks.

     - parameter weakTarget: The weak target.
     */
    func selectorCalled(on weakTarget: WeakTarget) {
        eventListener?.onEvent()
        dates.removeFirst()
        timer = nil
        startProducingEvents()
    }
}
