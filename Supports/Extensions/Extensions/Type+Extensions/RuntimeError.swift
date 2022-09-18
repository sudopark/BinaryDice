//
//  RuntimeError.swift
//  Extensions
//
//  Created by sudo.park on 2022/09/17.
//

import Foundation


public struct RuntimeError: Error {
    
    public let key: String
    public let message: String
    
    public init(
        _ key: String = "plain",
        _ message: String
    ) {
        self.key = key
        self.message = message
    }
}
