//
//  Time+Extensions.swift
//  Extensions
//
//  Created by sudo.park on 2022/09/12.
//

import Foundation


public typealias TimeStamp = Double


extension TimeStamp {
    
    public static func now() -> TimeStamp {
        return Date().timeIntervalSince1970
    }
}
