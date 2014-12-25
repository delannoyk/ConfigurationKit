//
//  KDERemoteConfigurationParser.swift
//  KDEConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

public protocol KDERemoteConfigurationParser: NSObjectProtocol {
    func parseData(data: NSData) -> (configuration: [String: String]?, error: NSError?)
}
