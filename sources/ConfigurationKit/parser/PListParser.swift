//
//  PListParser.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 25/07/15.
//  Copyright © 2015 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 Represents an error that occurs during data parsing.

 - PListIsNotValidDictionary: The PList isn't castable as a [String: String].
 */
public enum PListParsingError: ErrorType {
    case PListIsNotValidDictionary
}

/**
 *  An implementation of a Parser that reads a configuration from plist data.
 */
public struct PListParser: Parser {
    /**
     Parse data into a Dictionary where Key: String, Value: String.
     The result of this parsing should be a valid configuration.

     - parameter data: The data to parse.

     - throws: Throws an error if parsing fails.

     - returns: A valid configuration.
     */
    public func parseData(data: NSData) throws -> [String: String] {
        if let dictionary = try NSPropertyListSerialization.propertyListWithData(data, options: [], format: nil) as? [String: String] {
            return dictionary
        }
        throw PListParsingError.PListIsNotValidDictionary
    }
}
