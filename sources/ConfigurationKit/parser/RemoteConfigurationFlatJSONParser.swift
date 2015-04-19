//
//  RemoteConfigurationFlatJSONParser.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

public final class RemoteConfigurationFlatJSONParser: NSObject, RemoteConfigurationParser {
    public func parseData(data: NSData) -> Result<[String: String]> {
        var error: NSError? = nil
        if let JSONObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as? [String: String] {
            return .Success(Box(JSONObject))
        }
        return .Failure(error ?? NSError(domain: "RemoteConfigurationFlatJSONParser", code: 0, userInfo: nil))
    }
}
