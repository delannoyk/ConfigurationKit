//
//  URLBuilder.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

public protocol URLBuilder {
    func URLRequest() -> NSURLRequest
}
