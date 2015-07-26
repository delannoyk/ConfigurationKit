//
//  SimpleURLBuilder.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

public final class SimpleURLBuilder: NSObject, URLBuilder {
    private let _URLRequest: NSURLRequest

    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    public convenience init(URL: NSURL) {
        self.init(URLRequest: NSURLRequest(URL: URL))
    }

    public init(URLRequest: NSURLRequest) {
        _URLRequest = URLRequest
        super.init()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: URLBuilder
    ////////////////////////////////////////////////////////////////////////////

    public func URLRequest() -> NSURLRequest {
        return _URLRequest
    }

    ////////////////////////////////////////////////////////////////////////////
}
