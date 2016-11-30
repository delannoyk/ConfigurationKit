//
//  FlatJSONParser.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright © 2015 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 Represents an error that occurs during data parsing.

 - PListIsNotValidDictionary: The PList isn't castable as a [String: String].
 */
public enum FlatJSONParsingError: Error {
    case jsonIsNotFlatDictionaryOfStrings
}

/**
 *  An implementation of a Parser that reads a configuration from plist data.
 */
public struct FlatJSONParser: Parser {
    /// Initializes a FlatJSONParser.
    public init() { }

    /**
     Parse data into a Dictionary where Key: String, Value: String. The result of this parsing
     should be a valid configuration.

     - parameter data: The data to parse.

     - throws: An error if parsing fails.

     - returns: A valid configuration.
     */
    public func parse(_ data: Data) throws -> [String: String] {
        let JSONObject = try JSONSerialization.jsonObject(with: data,
            options: [])

        if let JSONObject = JSONObject as? [String: String] {
            return JSONObject
        }
        throw FlatJSONParsingError.jsonIsNotFlatDictionaryOfStrings
    }
}
