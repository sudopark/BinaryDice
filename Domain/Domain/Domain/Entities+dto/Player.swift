//
//  Player.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public typealias PlayerId = String

public struct Player {
    
    public let userID: String
    public let nickName: String
    public var thumbnail: String?
}
