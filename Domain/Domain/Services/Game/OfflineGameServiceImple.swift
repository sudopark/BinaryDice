//
//  OfflineGameService.swift
//  Domain
//
//  Created by sudo.park on 2022/09/11.
//

import Foundation
import Combine


public final class OfflineGameServiceImple: GameService {
    
    private let gameInfo: GameInfo
    private let diceRoller: RandDomiceRoller
    
    public init(
        _ gameInfo: GameInfo,
        diceRoller: RandDomiceRoller
    ) {
        self.gameInfo = gameInfo
        self.diceRoller = diceRoller
    }
    
    public var gameEvents: AnyPublisher<GameEvent, Never> {
        return Empty().eraseToAnyPublisher()
    }
}


// MARK: - prepare game

extension OfflineGameServiceImple {
    
    public func enterGame(_ player: Player) {
        
    }
}


// MARK: - process game

extension OfflineGameServiceImple {
    
    public func rollDice(_ playerId: String) {
        
    }
    
    public func moveKnight(_ knightIds: [String], at path: KnightMovePath) {
        
    }
}


// MARK: - leave the game

extension OfflineGameServiceImple {
    
    public func surrendGame(_ playerId: String) {
        
    }
    
    public func quitGame(_ playerId: String) {
        
    }
}
