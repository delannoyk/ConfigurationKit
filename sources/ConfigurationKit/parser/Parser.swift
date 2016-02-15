//
//  Parser.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright © 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `Parser` transforms NSData fetched from the URLRequest returned by the
 *  `URLBuilder` into a configuration.
 */
public protocol Parser {
    /**
     Parse data into a Dictionary where Key: String, Value: String.
     The result of this parsing should be a valid configuration.

     - parameter data: The data to parse.

     - throws: Throws an error if parsing fails.

     - returns: A valid configuration.
     */
    func parseData(data: NSData) throws -> [String: String]
}
