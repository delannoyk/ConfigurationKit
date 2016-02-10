//
//  DictionaryExtension.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 09/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import UIKit

enum Change<Key, Value> {
    case Addition(Key, Value)
    case Change(Key, Value, Value)
    case Removal(Key, Value)

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

    var isAddition: Bool {
        switch self {
        case .Addition:
            return true
        default:
            return false
        }
    }

    var isChange: Bool {
        switch self {
        case .Change:
            return true
        default:
            return false
        }
    }

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
