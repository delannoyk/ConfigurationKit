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
    func storeData(data: NSData, atKey key: String) throws

    /**
     Removes previously stored data.

     - parameter key: The key where the data is supposed.
     */
    func removeDataAtKey(key: String)

    /**
     Retrieves previously stored data.

     - parameter key: The key where the data is supposed to be stored at.

     - returns: Stored data if existing or nil.
     */
    func dataAtKey(key: String) -> NSData?
}
