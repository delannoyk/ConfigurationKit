//
//  KDEConfigurationSimpleURLBuilder.swift
//  KDEConfigurationKit
//
//  Created by Kevin DELANNOY on 14/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

public class KDESimpleURLBuilder: NSObject, KDEURLBuilder {
    private var _URLRequest: NSURLRequest

    // MARK: - Initialization
    ////////////////////////////////////////////////////////////////////////////

    public convenience init(URL: NSURL) {
        self.init(URLRequest: NSURLRequest(URL: URL))
    }

    public init(URLRequest: NSURLRequest) {
        self._URLRequest = URLRequest
        super.init()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: - KDEConfigurationURLBuilder
    ////////////////////////////////////////////////////////////////////////////

    public func URLRequest() -> NSURLRequest {
        return self._URLRequest
    }

    ////////////////////////////////////////////////////////////////////////////
}
