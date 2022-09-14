//
//  Battle.swift
//  Domain
//
//  Created by sudo.park on 2022/09/14.
//

import Foundation

public struct Battle: Equatable, Sendable {
    
    public let at: Node
    public let killer: Knights
    public let killed: Knights
    public let survived: Knights
}
