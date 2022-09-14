//
//  GameEvents.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public protocol GameEvent: Sendable { }

public struct GameStartEvent: GameEvent {
    public let info: GameInfo
    public let firstPlayerId: String
    public let positions: [KnightPosition]
}

public struct GameTurnChangeEvent: GameEvent {
    public let turn: GameTurn
}

public struct RollDiceEvent: GameEvent {
    public let playerId: String
    public let result: BinaryDice
}

public struct NodeOccupationUpdateEvent: GameEvent {
    
    public let movemensts: [KnightMovement]
    public let battles: [Battle]
    public let knightPositions: [KnightPosition]
}

public struct ScoreUpdateEvent: GameEvent {
    public let scoreMap: [PlayerId: Int]
}

public struct GameTurnUpdateEvent: GameEvent {
    public let turn: GameTurn
}

public struct GameQuitEvent: GameEvent {
    public let quitPlayerId: String
}

public struct GameEndEvent: GameEvent {
    public let winnerId: String
    public let finalScores: [String: Int]
}
