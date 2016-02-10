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
enum Change<Key, Value> {
    case Addition(Key, Value)
    case Change(Key, Value, Value)
    case Removal(Key, Value)

    /// Returns the impacted key.
    var key: Key {
        switch self {
        case .Addition(let key, _):
            return key
        case .Change(let key, _, _):
            return key
        case .Removal(let key, _):
            return key
        }
    }

    /// Returns the old value.
    var oldValue: Value? {
        switch self {
        case .Change(_, let value, _):
            return value
        case .Removal(_, let value):
            return value
        default:
            return nil
        }
    }

    /// Returns the new value.
    var newValue: Value? {
        switch self {
        case .Addition(_, let value):
            return value
        case .Change(_, _, let value):
            return value
        default:
            return nil
        }
    }

    /// Returns a boolean value indicating whether the change is an addition or not.
    var isAddition: Bool {
        switch self {
        case .Addition:
            return true
        default:
            return false
        }
    }

    /// Returns a boolean value indicating whether the change is a value change or not.
    var isChange: Bool {
        switch self {
        case .Change:
            return true
        default:
            return false
        }
    }

    /// Returns a boolean value indicating whether the change is a removal or not.
    var isRemoval: Bool {
        switch self {
        case .Removal:
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
    func delta(other: [Key: Value]) -> [Change<Key, Value>] {
        var changes = [Change<Key, Value>]()
        //Let's look for changes and removals
        for (key, lhsValue) in self {
            if let rhsValue = other[key] {
                if lhsValue != rhsValue {
                    //Value changes
                    changes.append(.Change(key, lhsValue, rhsValue))
                }
            }
            else {
                //Removal
                changes.append(.Removal(key, lhsValue))
            }
        }

        //Let's look for additions
        let keys = other.keys.filter { (self[$0] == nil) }
        for key in keys {
            changes.append(.Addition(key, other[key]!))
        }
        return changes
    }
}
