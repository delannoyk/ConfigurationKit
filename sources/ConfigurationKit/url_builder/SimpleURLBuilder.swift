//
//  SimpleURLBuilder.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import Foundation

public struct SimpleURLBuilder: URLBuilder {
    private let _URLRequest: NSURLRequest

    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    public init(URL: NSURL) {
        self.init(URLRequest: NSURLRequest(URL: URL))
    }

    public init(URLRequest: NSURLRequest) {
        _URLRequest = URLRequest
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: URLBuilder
    ////////////////////////////////////////////////////////////////////////////

    public func URLRequest() -> NSURLRequest {
        return _URLRequest
    }

    ////////////////////////////////////////////////////////////////////////////
}
