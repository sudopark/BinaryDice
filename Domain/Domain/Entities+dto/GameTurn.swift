//
//  GameTurn.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation
import Extensions
import Prelude
import Optics


public struct GameTurn: Sendable {
    
    public let sequeceId: Int
    public let playerId: String
    public var expireTime: TimeStamp
    
    public var remainRollChanceCount = 1
    public var pendingRollsForMove: [BinaryDice: Int] = [:]
}

extension GameTurn {
    
    func appendPendingDice(_ dice: BinaryDice) -> GameTurn {
        let newPending = self.pendingRollsForMove
            |> key(dice) %~ { ($0 ?? 0) + 1 }
        return self
            |> \.pendingRollsForMove .~ newPending
    }
    
    func removePendingDice(_ dices: [BinaryDice]) -> GameTurn {
        
        let removingCountMap = dices.reduce([BinaryDice: Int]()) { acc, dice in
            acc |> key(dice) %~ { ($0 ?? 0) + 1 }
        }
        let allDices: [BinaryDice] = [
            .doe(isBackward: false), .doe(isBackward: true), .gae, .gul, .yut, .mo
        ]
            
        let remainPending = allDices.reduce(into: [BinaryDice: Int]()) { acc, k in
            acc[k] = (pendingRollsForMove[k] ?? 0) - (removingCountMap[k] ?? 0)
        }
        return self
            |> \.pendingRollsForMove .~ remainPending
            .filter { $0.value > 0 }
    }
}
