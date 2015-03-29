//
//  KDERemoteConfigurationFlatJSONParser.swift
//  KDEConfigurationKit
//
//  Created by Kevin DELANNOY on 29/03/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit

public class KDERemoteConfigurationFlatJSONParser: NSObject, KDERemoteConfigurationParser {
    public func parseData(data: NSData) -> KDEResult<[String: String]> {
        var error: NSError? = nil
        if let JSONObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as? [String: String] {
            return .Success(KDEBox(JSONObject))
        }
        return .Failure(error ?? NSError(domain: "KDERemoteConfigurationFlatJSONParser", code: 0, userInfo: nil))
    }
}
