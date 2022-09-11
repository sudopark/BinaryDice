//
//  GameInfo.swift
//  Domain
//
//  Created by sudo.park on 2022/09/12.
//

import Foundation

public struct GameInfo: Sendable {
    
    public let gameId: String
    public let players: [Player]
    public let knights: [PlayerId: [Knight]]
    
    public init(
        gameId: String,
        players: [Player],
        knights: [PlayerId: [Knight]]
    ) {
        self.gameId = gameId
        self.players = players
        self.knights = knights
    }
}

