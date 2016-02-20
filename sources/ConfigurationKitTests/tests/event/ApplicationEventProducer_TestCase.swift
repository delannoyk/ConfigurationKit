//
//  ApplicationEventProducer_TestCase.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 20/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import ConfigurationKit

class E: EventListener {
    var onEventClosure: (Void -> Void)?
    var eventCount = 0

    func onEvent() {
        eventCount++
        onEventClosure?()
    }
}

class ApplicationEventProducer_TestCase: XCTestCase {
    func testNoEventProductionWhenNotStarted() {
        let listener = E()

        let producer = ApplicationEventProducer()
        producer.eventListener = listener

        //Note that we didn't start producing events so sending a notification
        //should not fire any event.
        listener.onEventClosure = {
            XCTFail()
        }

        //Let's try that
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
    }

    func testEventProductionWhenStarted() {
        let listener = E()

        let producer = ApplicationEventProducer()
        producer.eventListener = listener
        producer.startProducingEvents()

        //Let's start producing event and then retry sending a notification.
        let expectationToReceiveEvent = expectationWithDescription("Let's wait for an event")
        listener.onEventClosure = {
            expectationToReceiveEvent.fulfill()
        }

        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())

        waitForExpectationsWithTimeout(1) { error in
            if let _ = error {
                XCTFail()
            }
        }
    }

    func testNoEventProductionWhenStopped() {
        let listener = E()

        let producer = ApplicationEventProducer()
        producer.eventListener = listener
        producer.startProducingEvents()
        producer.stopProducingEvents()

        //Ok, same thing but we stop producing events
        listener.onEventClosure = {
            XCTFail()
        }

        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
    }

    func testEventsAreOnlyGeneratedOnceWhenStartIsCalledMultipleTimes() {
        let listener = E()

        let producer = ApplicationEventProducer()
        producer.eventListener = listener
        producer.startProducingEvents()
        producer.startProducingEvents()

        //Let's start producing event and then retry sending a notification.
        let expectationToReceiveEvent = expectationWithDescription("Let's wait for an event")
        listener.onEventClosure = {
            expectationToReceiveEvent.fulfill()
        }

        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())

        waitForExpectationsWithTimeout(1) { error in
            XCTAssert(listener.eventCount == 1)

            if let _ = error {
                XCTFail()
            }
        }
    }

    func testNoEventProductionWhenStoppedMultipleTimes() {
        let listener = E()

        let producer = ApplicationEventProducer()
        producer.eventListener = listener
        producer.startProducingEvents()
        producer.stopProducingEvents()
        producer.stopProducingEvents()

        //Ok, same thing but we stop producing events
        listener.onEventClosure = {
            XCTFail()
        }

        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
    }
}
