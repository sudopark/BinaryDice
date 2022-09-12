//
//  OfflineGameService.swift
//  Domain
//
//  Created by sudo.park on 2022/09/11.
//

import Foundation
import Combine
import Prelude
import Optics


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
    
    private struct Subjects: Sendable {
        let events = PassthroughSubject<GameEvent, Never>()
        let onlinePlayerIds = CurrentValueSubject<Set<String>, Never>([])
        let currentTurn = CurrentValueSubject<GameTurn?, Never>(nil)
    }
    private let subject = Subjects()
    
    public var gameEvents: AnyPublisher<GameEvent, Never> {
        return self.subject.events
            .eraseToAnyPublisher()
    }
}


// MARK: - prepare game

extension OfflineGameServiceImple {
    
    public func enterGame(_ player: Player) {
        let newIds = self.subject.onlinePlayerIds.value <> [player.userId]
        self.subject.onlinePlayerIds.send(newIds)
        
        let (isAllEnter, isGameNotStart) = (
            newIds.count == self.gameInfo.players.count,
            self.subject.currentTurn.value == nil
        )
        guard isAllEnter, isGameNotStart else { return }
        self.startGame()
    }
    
    private func startGame() {
        guard let firstPlayerId = self.gameInfo.players.first?.userId else { return }
        let startEvent = GameStartEvent(info: self.gameInfo, firstPlayerId: firstPlayerId)
        self.subject.events.send(startEvent)
        
        let turn = GameTurn(sequeceId: 0, playerId: firstPlayerId, expireTime: .now() + 60_000)
        self.subject.currentTurn.send(turn)
        self.subject.events.send(GameTurnChangeEvent(turn: turn))
    }
}


// MARK: - process game

extension OfflineGameServiceImple {
    
    public func rollDice(_ playerId: String) {
        guard let currentTurn = self.subject.currentTurn.value,
              currentTurn.playerId == playerId,
              currentTurn.remainRollChangeCount > 0
        else { return }
        
        let dice = self.diceRoller.roll()
        let diceEvent = RollDiceEvent(playerId: playerId, result: dice)
        self.subject.events.send(diceEvent)
        
        let newTurn = currentTurn
            |> \.remainRollChangeCount -~ (dice.isRollOneMoreTime ? 0 : 1)
            |> \.pendingRollsForMove %~ { $0 + [dice] }
            |> \.expireTime +~ 60
        self.subject.currentTurn.send(newTurn)
        self.subject.events.send(GameTurnUpdateEvent(turn: newTurn))
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
