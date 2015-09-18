//
//  StringExtension.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 17/04/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

internal extension String {
    static var documentPath: String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
    }
}
