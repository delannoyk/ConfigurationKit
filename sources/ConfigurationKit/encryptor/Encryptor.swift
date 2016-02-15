//
//  Encryptor.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 10/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `CacheEncryptor` is used to encrypt/decrypt your configuration file.
 */
public protocol Encryptor {
    /**
     This should encrypt data using the algorithm you want.

     - parameter data: Data to encrypt.

     - returns: The encrypted value of `data`.
     */
    func encryptedData(data: NSData) -> NSData

    /**
     This should decrypt data using the algorithm you want (fitting your
     `encryptData:` implementation).

     - parameter data: Data to decrypt.

     - returns: The decrypted value of `data`.
     */
    func decryptedData(data: NSData) -> NSData
}
