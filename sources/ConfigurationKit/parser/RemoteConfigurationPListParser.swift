//
//  RemoteConfigurationPListParser.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 25/07/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import Foundation

public struct RemoteConfigurationPListParser: RemoteConfigurationParser {
    let format: NSPropertyListFormat

    public init(format: NSPropertyListFormat) {
        self.format = format
    }

    public func parseData(data: NSData) -> Result<[String: String]> {
        do {
            var format = self.format
            if let dictionary = try NSPropertyListSerialization.propertyListWithData(data, options: [], format: &format) as? [String: String] {
                return .Success(dictionary)
            }
        }
        catch let error as NSError {
            return .Failure(error)
        }
        return .Failure(NSError(domain: "\(RemoteConfigurationPListParser.self)", code: 0, userInfo: nil))
    }
}
