//
//  GameEvents.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public protocol GameEvent { }

public struct GameStartEvent: GameEvent {
    public let info: GameInfo
    public let firstPlayerId: String
}

public struct GameTurnChangeEvent: GameEvent {
    public let turn: GameTurn
}

public struct RollDiceEvent: GameEvent {
    public let playerId: String
    public let result: BinaryDice
}

public struct NodeOccupationUpdateEvent: GameEvent {
    
    public struct Movement: Equatable {
        public let knights: Knights
        public let path: KnightMovePath
    }
    
    public struct Battle: Equatable {
        public let at: Node
        public let killed: Knights
    }
    
    public struct Merging: Equatable {
        public let at: Node
        public let newKnights: Knights
    }
    
    public let movemensts: [Movement]
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
