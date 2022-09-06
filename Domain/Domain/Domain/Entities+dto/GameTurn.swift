//
//  GameTurn.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public struct GameTurn {
    
    public let playerID: String
    public let remainMove: Int = 1
    
    public var diceRolls: [BinaryDice] = []
    
    public var isEnd: Bool { self.remainMove == 0 }
}
