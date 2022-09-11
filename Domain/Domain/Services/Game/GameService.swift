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
 
    func rollDice(_ playerId: String)
    
    func moveKnight(_ knightIds: [String], at path: KnightMovePath)
    
    func surrendGame(_ playerId: String)
    
    func quitGame(_ playerId: String)
    
    var gameEvents: AnyPublisher<GameEvent, Never> { get }
}
