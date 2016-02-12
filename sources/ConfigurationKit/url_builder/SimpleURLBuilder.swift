//
//  SimpleURLBuilder.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright © 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `SimpleURLBuilder` is an URLBuilder implementation that uses a static URL
 *  to download periodically a configuration file.
 */
public struct SimpleURLBuilder: URLBuilder {
    /// The URLRequest.
    private let _URLRequest: NSURLRequest

    /**
    Initializes a `SimpleURLBuilder` with a `NSURL`.

    - parameter URL: The URL heading to a configuration file.

    - returns: An initialized `SimpleURLBuilder`.
    */
    public init(URL: NSURL) {
        self.init(URLRequest: NSURLRequest(URL: URL))
    }

    /**
     Initializes a `SimpleURLBuilder` with a `NSURLRequest`.

     - parameter URLRequest: The URLRequest heading to a configuration file.

     - returns: An initialized `SimpleURLBuilder`.
     */
    public init(URLRequest: NSURLRequest) {
        _URLRequest = URLRequest
    }


    /**
    Returns the `NSURLRequest` built at initialization.

    - returns: The `NSURLRequest` built at initialization.
    */
    public func URLRequest() -> NSURLRequest {
        return _URLRequest
    }
}
