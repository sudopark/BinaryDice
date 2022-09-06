//
//  GameService.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation
import Combine

                                    
public protocol GameService {
    
    func setupKnights(_ playerId: String, pieces: [Knight])
    
    func rollDice(_ playerId: String, result: BinaryDice)
    
    func moveKnight(_ knightId: String, to node: Node)
    
    var gameEvents: AnyPublisher<GameEvent, Never> { get }
}
