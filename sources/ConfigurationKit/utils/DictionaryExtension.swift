//
//  DictionaryExtension.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 09/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 Represents a change.

 - Addition: An addition. The key didn't exist before.
 - Change:   A change. The `oldValue` differs from the `newValue`.
 - Removal:  A removal. The key doesn't exist anymore.
 */
public enum Change<Key, Value> {
    case addition(Key, Value)
    case change(Key, Value, Value)
    case removal(Key, Value)

    /// Returns the impacted key.
    public var key: Key {
        switch self {
        case .addition(let key, _):
            return key
        case .change(let key, _, _):
            return key
        case .removal(let key, _):
            return key
        }
    }

    /// Returns the old value.
    public var oldValue: Value? {
        switch self {
        case .change(_, let value, _):
            return value
        case .removal(_, let value):
            return value
        default:
            return nil
        }
    }

    /// Returns the new value.
    public var newValue: Value? {
        switch self {
        case .addition(_, let value):
            return value
        case .change(_, _, let value):
            return value
        default:
            return nil
        }
    }

    /// Returns a boolean value indicating whether the change is an addition or not.
    public var isAddition: Bool {
        switch self {
        case .addition:
            return true
        default:
            return false
        }
    }

    /// Returns a boolean value indicating whether the change is a value change or not.
    public var isChange: Bool {
        switch self {
        case .change:
            return true
        default:
            return false
        }
    }

    /// Returns a boolean value indicating whether the change is a removal or not.
    public var isRemoval: Bool {
        switch self {
        case .removal:
            return true
        default:
            return false
        }
    }
}

extension Dictionary where Value: Equatable {
    /**
     Computes differences between 2 dictionaries.

     - parameter other: The dictionary to compute the difference with.

     - returns: List of changes.
     */
    func delta(_ other: [Key: Value]) -> [Change<Key, Value>] {
        var changes = [Change<Key, Value>]()
        //Let's look for changes and removals
        for (key, lhsValue) in self {
            if let rhsValue = other[key] {
                if lhsValue != rhsValue {
                    //Value changes
                    changes.append(.change(key, lhsValue, rhsValue))
                }
            } else {
                //Removal
                changes.append(.removal(key, lhsValue))
            }
        }

        //Let's look for additions
        let keys = other.keys.filter { (self[$0] == nil) }
        for key in keys {
            changes.append(.addition(key, other[key]!))
        }
        return changes
    }
}
