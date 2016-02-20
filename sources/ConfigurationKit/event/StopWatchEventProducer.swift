//
//  StopWatchEventProducer.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 11/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `WeakTarget` is used so that a NSTimer doesn't retain the real target
 *  and the real target can invalidate the timer in its deinit.
 */
private class WeakTarget: NSObject {
    weak var target: StopWatchEventProducer?

    init(_ target: StopWatchEventProducer) {
        self.target = target
    }

    @objc func selector(timer: NSTimer) {
        target?.timerTicked(timer)
    }
}

/**
 *  A `StopWatchEventProducer` generates events at regular interval.
 */
public class StopWatchEventProducer: NSObject, EventProducer {
    /// The timer.
    private var timer: NSTimer?

    /// The time interval used to generate events.
    public var timeInterval: NSTimeInterval {
        didSet {
            if let _ = timer {
                stopProducingEvents()
                startProducingEvents()
            }
        }
    }

    /// The event listener.
    public weak var eventListener: EventListener?


    /**
     Initializes a `StopWatchEventProducer`.

     - parameter timeInterval: The time interval to wait before generating new
         events.

     - returns: An initialized `StopWatchEventProducer`.
     */
    public init(timeInterval: NSTimeInterval) {
        self.timeInterval = timeInterval
    }

    /**
     Stops producing events.
     */
    deinit {
        stopProducingEvents()
    }


    /**
     Creates a timer that will generate events at regular interval.
     */
    public func startProducingEvents() {
        guard timer == nil else {
            return
        }

        timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval,
            target: WeakTarget(self),
            selector: "selector:",
            userInfo: nil,
            repeats: true)
    }

    /**
     Stops the timer.
     */
    public func stopProducingEvents() {
        guard let timer = timer else {
            return
        }

        timer.invalidate()
        self.timer = nil
    }

    /**
     Method that gets called when the timer ticks.

     - parameter timer: The timer.
     */
    private func timerTicked(timer: NSTimer) {
        eventListener?.onEvent()
    }
}
