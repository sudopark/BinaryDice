//
//  GameService.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation
import Combine

                                    
public protocol GameService: Sendable {
 
    func enterGame(_ player: Player)
    
    func ack(_ eventId: String, from playerId: String)
 
    func rollDice(_ playerId: String) async throws
    
    func moveKnight(
        _ playerId: String,
        _ knightIds: [String],
        through path: KnightMovePath
    ) async throws
    
    func surrendGame(_ playerId: String)
    
    func quitGame(_ playerId: String)
    
    var gameEvents: AnyPublisher<GameEvent, Never> { get }
}
