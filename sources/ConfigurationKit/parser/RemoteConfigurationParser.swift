//
//  RemoteConfigurationParser.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

public final class Box<T> {
    public let value: T

    internal init(_ value: T) {
        self.value = value
    }
}

public enum Result<T> {
    case Success(Box<T>)
    case Failure(NSError)

    public var isSuccessful: Bool {
        switch self {
        case .Success(_):
            return true
        default:
            return false
        }
    }

    public var result: T? {
        switch self {
        case .Success(let result):
            return result.value
        default:
            return nil
        }
    }

    public var error: NSError? {
        switch self {
        case .Failure(let error):
            return error
        default:
            return nil
        }
    }
}

public protocol RemoteConfigurationParser {
    func parseData(data: NSData) -> Result<[String: String]>
}
