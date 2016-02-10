//
//  RemoteConfigurationFlatJSONParser.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import Foundation

public struct RemoteConfigurationFlatJSONParser: RemoteConfigurationParser {
    public init() {
    }

    public func parseData(data: NSData) -> Result<[String: String]> {
        do {
            if let JSONObject = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: String] {
                return .Success(Box(JSONObject))
            }
        }
        catch let error as NSError {
            return .Failure(error)
        }
        return .Failure(NSError(domain: "\(RemoteConfigurationFlatJSONParser.self)", code: 0, userInfo: nil))
    }
}
