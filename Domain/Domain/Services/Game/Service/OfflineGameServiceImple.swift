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


public final class OfflineGameServiceImple: GameService, @unchecked Sendable {
    
    private let gameInfo: GameInfo
    private let diceRoller: RandDomiceRoller
    
    public init(
        _ gameInfo: GameInfo,
        diceRoller: RandDomiceRoller
    ) {
        self.gameInfo = gameInfo
        self.diceRoller = diceRoller
    }

    private var enterPlayerIds = Set<PlayerId>()
    private var currrentTurn: GameTurn?
    private var battleGround: BattleGround?
    private let events = PassthroughSubject<GameEvent, Never>()
    
    public var gameEvents: AnyPublisher<GameEvent, Never> {
        return self.events
            .eraseToAnyPublisher()
    }
    
    private func changeTurn(next playerId: String) {
        let nextSeq = self.currrentTurn.map { $0.sequeceId + 1 } ?? 0
        let newTurn = GameTurn(sequeceId: nextSeq, playerId: playerId, expireTime: .now() + 120)
        self.currrentTurn = newTurn
        self.events.send(GameTurnChangeEvent(turn: newTurn))
    }
    
    private func updateGameTurn(_ mutating: (GameTurn) -> GameTurn ) {
        guard let turn = self.currrentTurn else { return }
        let newTurn = mutating(turn)
        self.currrentTurn = newTurn
        self.events.send(GameTurnUpdateEvent(turn: newTurn))
    }
}


// MARK: - prepare game

extension OfflineGameServiceImple {
    
    public func enterGame(_ player: Player) {
        
        let newIds = self.enterPlayerIds <> [player.userId]
        self.enterPlayerIds = newIds
        
        let (isAllEnter, isGameNotStart) = (newIds.count == self.gameInfo.players.count, battleGround == nil)
        guard isAllEnter, isGameNotStart else { return }
        self.startGame()
    }
    
    private func startGame() {
        guard let firstPlayerId = self.gameInfo.players.first?.userId else { return }
        let battleGround = BattleGround(gameInfo: self.gameInfo)
        self.battleGround = battleGround
        
        let startEvent = GameStartEvent(
            info: self.gameInfo,
            firstPlayerId: firstPlayerId,
            positions: battleGround.knightPositions
        )
        self.events.send(startEvent)
        
        self.changeTurn(next: firstPlayerId)
    }
}


// MARK: - process game

extension OfflineGameServiceImple {
    
    public func rollDice(_ playerId: String) async throws {
        guard self.battleGround != nil,
              let currentTurn = self.currrentTurn,
              currentTurn.playerId == playerId,
              currentTurn.remainRollChanceCount > 0
        else { return }
        
        let dice = self.diceRoller.roll()
        let diceEvent = RollDiceEvent(playerId: playerId, result: dice)
        self.events.send(diceEvent)
        
        self.updateGameTurn { turn in
            turn
                |> \.remainRollChanceCount -~ (dice.isRollOneMoreTime ? 0 : 1)
                |> { $0.appendPendingDice(dice) }
        }
    }
    
    public func moveKnight(
        _ playerId: String,
        _ knightIds: [String],
        through path: KnightMovePath
    ) async throws {
        
        guard self.currrentTurn?.playerId == playerId,
              self.currrentTurn?.pendingRollsForMove.isEmpty == false,
              let result = self.battleGround?.moveKnight(knightIds, through: path),
              let newPositions = self.battleGround?.knightPositions
        else { return }
        
        let consumedDices = path.serialPaths.map { $0.dice }
        self.updateGameTurn { turn in
            return turn
                |> { $0.removePendingDice(consumedDices) }
        }
        
        self.events.send(NodeOccupationUpdateEvent(movemensts: result.0, battles: result.1, knightPositions: newPositions))
        
        self.checkGameIsEndOrUpdateTurn(playerId, by: result)
    }
    
    private func checkGameIsEndOrUpdateTurn(_ currentPlayerId: String, by result: BattleGround.MoveResult) {
        let (isKillCounter, remainDiceRollChance, winnerId) = (
            result.battles.isEmpty == false,
            (self.currrentTurn?.remainRollChanceCount ?? 0) > 0,
            self.battleGround?.allKnightsOutPlayerId()
        )
        switch (isKillCounter, remainDiceRollChance, winnerId) {
        case (_, _, let .some(playerId)):
            self.events.send(
                GameEndEvent(winnerId: playerId)
            )
            
        case (true, _, _):
            self.updateGameTurn { turn in
                return turn
                    |> \.remainRollChanceCount +~ result.battles.count
                    |> \.expireTime +~ 60
            }
            
        case (_, true, _): return
            
        default:
            guard let counter = self.gameInfo.players.filter ({ $0.userId != currentPlayerId }).first else { return }
            self.changeTurn(next: counter.userId)
        }
    }
}


// MARK: - leave the game

extension OfflineGameServiceImple {
    
    public func surrendGame(_ playerId: String) {
        
    }
    
    public func quitGame(_ playerId: String) {
        
    }
}
