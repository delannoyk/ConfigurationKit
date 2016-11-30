//
//  URLRequestBuilder.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright © 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  An `URLRequestBuilder` serves the purpose of building a `URLRequest`.
 */
public protocol URLRequestBuilder {
    /**
     Builds a `URLRequest` that heads to a configuration file.

     - returns: A valid `URLRequest` that heads to a configuration file.
     */
    func urlRequest() -> URLRequest
}
