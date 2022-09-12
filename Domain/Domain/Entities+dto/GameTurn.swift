//
//  GameTurn.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation
import Extensions


public struct GameTurn: Sendable {
    
    public let sequeceId: Int
    public let playerId: String
    public var expireTime: TimeStamp
    
    public var remainRollChangeCount = 1
    public var pendingRollsForMove: [BinaryDice] = []
}
