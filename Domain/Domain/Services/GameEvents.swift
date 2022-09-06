//
//  GameEvents.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public protocol GameEvent { }

public struct SetupKnightEvent: GameEvent {
    public let playerId: String
    public let knights: [Knight]
}

public struct GameStartEvent: GameEvent {
    public let firstPlayerId: String
}

public struct GameTurnChangeEvent: GameEvent {
    public let turn: GameTurn
}

public struct RollDiceEvent: GameEvent {
    public let playerId: String
    public let result: BinaryDice
}

public struct KnightMoveEvent: GameEvent {
    public let playerId: String
    public let knight: Knight
    public let node: Node
}

public struct KnightKillEvent: GameEvent {
    public let killer: Knight
    public let dead: Knight
    public let node: Node
    public let plusScore: Int
}

public struct ScoreUpdateEvent: GameEvent {
    public let playerId: String
    public let score: Int
}

public struct NodeOccupationUpdateEvent: GameEvent {
    
    public let occupied: [NodeId: Knights] = [:]
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
