//
//  URLBuilder.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright © 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  An `URLBuilder` serves the purpose of building a `NSURLRequest`.
 */
public protocol URLBuilder {
    /**
     Builds a `NSURLRequest` that heads to a configuration file.

     - returns: A valid `NSURLRequest` that heads to a configuration file.
     */
    func URLRequest() -> NSURLRequest
}
