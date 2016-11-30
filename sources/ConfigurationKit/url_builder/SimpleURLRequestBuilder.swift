//
//  SimpleURLBuilder.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright © 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `SimpleURLRequestBuilder` is an URLBuilder implementation that uses a static URL to download
 *  periodically a configuration file.
 */
public struct SimpleURLRequestBuilder: URLRequestBuilder {
    /// The URLRequest.
    private let _urlRequest: URLRequest

    /**
    Initializes a `SimpleURLBuilder` with a `NSURL`.

    - parameter url: The URL heading to a configuration file.
    */
    public init(url: URL) {
        self.init(urlRequest: URLRequest(url: url))
    }

    /**
     Initializes a `SimpleURLBuilder` with a `NSURLRequest`.

     - parameter urlRequest: The URLRequest heading to a configuration file.
     */
    public init(urlRequest: URLRequest) {
        _urlRequest = urlRequest
    }


    /**
    Returns the `NSURLRequest` built at initialization.

    - returns: The `NSURLRequest` built at initialization.
    */
    public func urlRequest() -> URLRequest {
        return _urlRequest
    }
}
