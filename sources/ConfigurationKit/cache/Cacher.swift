//
//  Cacher.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright © 2015 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `Cacher` serves the purpose of saving a new configuration persistently.
 */
public protocol Cacher {
    /**
     Caches data at the location you want (File, Keychain, ?).

     - parameter data: The data to be stored.
     - parameter key:  The key to save the data at.

     - throws: Throws an error if caching failed.
     */
    func store(_ data: Data, at key: String) throws

    /**
     Removes previously stored data.

     - parameter key: The key where the data is supposed.
     */
    func remove(at key: String)

    /**
     Retrieves previously stored data.

     - parameter key: The key where the data is supposed to be stored at.

     - returns: Stored data if existing or nil.
     */
    func data(at key: String) -> Data?

    /**
     Returns a boolean value indicating whether the cacher has data for a specific key.

     - parameter key: The key where the data is supposed to be stored at.

     - returns: A boolean value indicating whether the cacher has data for a specific key
     */
    func hasData(at key: String) -> Bool
}
