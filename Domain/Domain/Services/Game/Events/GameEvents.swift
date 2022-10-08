//
//  GameEvents.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public protocol GameEvent: Sendable {
    var uuid: String { get }
}

public struct PlayerPresenceChanged: GameEvent {
    public let uuid: String = UUID().uuidString
    public let playerId: String
    public let isOn: Bool
}

public struct GameStartEvent: GameEvent {
    public let uuid: String = UUID().uuidString
    public let info: GameInfo
    public let firstPlayerId: String
    public let positions: [KnightPosition]
}

public struct GameTurnChangeEvent: GameEvent {
    public let uuid: String = UUID().uuidString
    public let turn: GameTurn
}

public struct RollDiceEvent: GameEvent {
    public let uuid: String = UUID().uuidString
    public let playerId: String
    public let result: BinaryDice
}

public struct NodeOccupationUpdateEvent: GameEvent {
    
    public let uuid: String = UUID().uuidString
    public let movemensts: [KnightMovement]
    public let battles: [Battle]
    public let knightPositions: [KnightPosition]
}

public struct GameTurnUpdateEvent: GameEvent {
    public let uuid: String = UUID().uuidString
    public let turn: GameTurn
}

public struct GameQuitEvent: GameEvent {
    public let uuid: String = UUID().uuidString
    public let quitPlayerId: String
}

public struct GameEndEvent: GameEvent {
    public let uuid: String = UUID().uuidString
    public let winnerId: String
}
