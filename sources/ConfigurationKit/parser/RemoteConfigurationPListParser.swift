//
//  RemoteConfigurationPListParser.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 25/07/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

public struct RemoteConfigurationPListParser: RemoteConfigurationParser {
    let format: NSPropertyListFormat

    public init(format: NSPropertyListFormat) {
        self.format = format
    }

    public func parseData(data: NSData) -> Result<[String: String]> {
        var error: NSError?
        var format = self.format

        if let dictionary = NSPropertyListSerialization.propertyListWithData(data, options: .allZeros, format: &format, error: &error) as? [String: String] {
            return .Success(Box(dictionary))
        }
        return .Failure(NSError(domain: "\(RemoteConfigurationPListParser.self)", code: 0, userInfo: nil))
    }
}
