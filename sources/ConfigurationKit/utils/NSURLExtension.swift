//
//  NSURLExtension.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 18/09/15.
//  Copyright © 2015 Kevin Delannoy. All rights reserved.
//

import Foundation

internal extension NSURL {
    func createDirectoryIfNecesserary() throws {
        if let path = path where !NSFileManager.defaultManager().fileExistsAtPath(path) {
            try NSFileManager.defaultManager().createDirectoryAtURL(self,
                withIntermediateDirectories: true, attributes: nil)
        }
    }
}
