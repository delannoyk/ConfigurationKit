//
//  KDERemoteConfigurationCacheEncryptor.swift
//  KDEConfigurationKit
//
//  Created by Kevin DELANNOY on 18/04/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

public protocol KDERemoteConfigurationCacheEncryptor: NSObjectProtocol {
    func encryptedData(fromData data: NSData) -> NSData
    func decryptedData(fromData data: NSData) -> NSData
}
