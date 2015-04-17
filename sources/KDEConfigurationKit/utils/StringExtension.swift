//
//  StringExtension.swift
//  KDEConfigurationKit
//
//  Created by Kevin DELANNOY on 17/04/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

internal extension String {
    static var documentPath: String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    }

    func createDirectoryIfNecesserary() {
        if !NSFileManager.defaultManager().fileExistsAtPath(self) {
            NSFileManager.defaultManager().createDirectoryAtPath(self,
                withIntermediateDirectories: true, attributes: nil, error: nil)
        }
    }
}
