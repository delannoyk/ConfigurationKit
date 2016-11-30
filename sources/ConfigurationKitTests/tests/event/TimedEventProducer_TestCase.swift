//
//  TimedEventProducer_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 20/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

class TimedEventProducer_TestCase: XCTestCase {
    func testNoEventProductionWhenNotStarted() {
        let listener = E()

        let producer = TimedEventProducer(dates: [Date(timeIntervalSinceNow: 1)])
        producer.eventListener = listener

        let e = expectation(description: "Waiting for the timer to fire")
        listener.onEventClosure = {
            XCTFail()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
            e.fulfill()
        }

        //Let's wait 1sec
        waitForExpectations(timeout: 2) { error in
        }
    }

    func testEventProductionWhenStarted() {
        let listener = E()

        let producer = TimedEventProducer(dates: [Date(timeIntervalSinceNow: 1)])
        producer.eventListener = listener
        producer.startProducingEvents()

        //Let's start producing event and then retry sending a notification.
        let expectationToReceiveEvent = expectation(description: "Let's wait for an event")
        listener.onEventClosure = {
            expectationToReceiveEvent.fulfill()
        }

        waitForExpectations(timeout: 1.5) { error in
            if let _ = error {
                XCTFail()
            }
        }
    }

    func testNoEventProductionWhenStopped() {
        let listener = E()

        let producer = TimedEventProducer(dates: [Date(timeIntervalSinceNow: 1)])
        producer.eventListener = listener
        producer.startProducingEvents()
        producer.stopProducingEvents()

        //Ok, same thing but we stop producing events
        let e = expectation(description: "Waiting for the timer to fire")
        listener.onEventClosure = {
            XCTFail()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
            e.fulfill()
        }

        //Let's wait 1sec
        waitForExpectations(timeout: 2) { error in
        }
    }
}
