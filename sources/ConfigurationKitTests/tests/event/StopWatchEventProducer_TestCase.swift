//
//  StopWatchEventProducer_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 20/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

class StopWatchEventProducer_TestCase: XCTestCase {
    func testNoEventProductionWhenNotStarted() {
        let listener = E()

        let producer = StopWatchEventProducer(timeInterval: 0.1)
        producer.eventListener = listener

        let expectation = expectationWithDescription("Waiting for the timer to fire")
        listener.onEventClosure = {
            XCTFail()
        }

        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            expectation.fulfill()
        }

        //Let's wait 1sec
        waitForExpectationsWithTimeout(1) { error in
        }
    }

    func testEventProductionWhenStarted() {
        let listener = E()

        let producer = StopWatchEventProducer(timeInterval: 0.1)
        producer.eventListener = listener
        producer.startProducingEvents()

        //Let's start producing event and then retry sending a notification.
        let expectationToReceiveEvent = expectationWithDescription("Let's wait for an event")
        listener.onEventClosure = {
            expectationToReceiveEvent.fulfill()
        }

        waitForExpectationsWithTimeout(1) { error in
            if let _ = error {
                XCTFail()
            }
        }
    }

    func testNoEventProductionWhenStopped() {
        let listener = E()

        let producer = StopWatchEventProducer(timeInterval: 0.1)
        producer.eventListener = listener
        producer.startProducingEvents()
        producer.stopProducingEvents()

        //Ok, same thing but we stop producing events
        let expectation = expectationWithDescription("Waiting for the timer to fire")
        listener.onEventClosure = {
            XCTFail()
        }

        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            expectation.fulfill()
        }

        //Let's wait 1sec
        waitForExpectationsWithTimeout(1) { error in
        }
    }
}
