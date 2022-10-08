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
    private let gameEventBroadCaster: GameEventBroadCaster
    
    public init(
        _ gameInfo: GameInfo,
        diceRoller: RandDomiceRoller,
        gameEventBroadCaster: GameEventBroadCaster
    ) {
        self.gameInfo = gameInfo
        self.diceRoller = diceRoller
        self.gameEventBroadCaster = gameEventBroadCaster
    }

    private var enterPlayerIds = Set<PlayerId>()
    private var currrentTurn: GameTurn?
    private var battleGround: BattleGround?
    
    public var gameEvents: AnyPublisher<GameEvent, Never> {
        return self.gameEventBroadCaster.gameEvents
    }
    
    @discardableResult
    private func changeTurn(next playerId: String, after previousEvent: GameEvent? = nil) -> GameTurnChangeEvent {
        let nextSeq = self.currrentTurn.map { $0.sequeceId + 1 } ?? 0
        let newTurn = GameTurn(sequeceId: nextSeq, playerId: playerId, expireTime: .now() + 120)
        self.currrentTurn = newTurn
        
        let changeEvent = GameTurnChangeEvent(turn: newTurn)
        self.sendEvent(changeEvent, after: previousEvent)
        return changeEvent
    }
    
    @discardableResult
    private func updateGameTurn(
        after previousEvent: GameEvent? = nil,
        _ mutating: (GameTurn) -> GameTurn
    ) -> GameTurnUpdateEvent {
        
        guard let turn = self.currrentTurn else { fatalError() }
        let newTurn = mutating(turn)
        self.currrentTurn = newTurn
        
        let updateEvent = GameTurnUpdateEvent(turn: newTurn)
        self.sendEvent(updateEvent, after: previousEvent)
        return updateEvent
    }
    
    private func sendEvent(_ event: GameEvent, after previousEvent: GameEvent? = nil) {
        let after: GameEventAfter? = previousEvent.map { .ack($0.uuid, waitTimeout: $0.consumeTimeout) }
        self.gameEventBroadCaster.sendEvent(event, after: after)
    }
}


// MARK: - prepare game

extension OfflineGameServiceImple {
    
    public func enterGame(_ player: Player) {
        
        let presenceEvent = PlayerPresenceChanged(playerId: player.userId, isOn: true)
        self.sendEvent(presenceEvent)
        
        let newIds = self.enterPlayerIds <> [player.userId]
        self.enterPlayerIds = newIds
        
        let (isAllEnter, isGameNotStart) = (newIds.count == self.gameInfo.players.count, battleGround == nil)
        guard isAllEnter, isGameNotStart else { return }
        self.startGame()
    }
    
    public func ack(_ eventId: String, from playerId: String) {
        let ack = GameAckEvent(eventId: eventId, playerId: playerId)
        self.gameEventBroadCaster.sendAck(ack)
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
        self.sendEvent(startEvent)
        
        self.changeTurn(next: firstPlayerId, after: startEvent)
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
        self.sendEvent(diceEvent)
        
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
        let updateEvent = self.updateGameTurn { turn in
            return turn
                |> { $0.removePendingDice(consumedDices) }
        }
        
        let occupationUpdateEvent = NodeOccupationUpdateEvent(
            movemensts: result.0,
            battles: result.1,
            knightPositions: newPositions
        )
        self.sendEvent(occupationUpdateEvent, after: updateEvent)
        
        self.publishGameIsEndOrUpdateTurn(playerId, by: result, after: occupationUpdateEvent)
    }
    
    private func publishGameIsEndOrUpdateTurn(
        _ currentPlayerId: String,
        by result: BattleGround.MoveResult,
        after previousEvent: GameEvent
    ) {
        let (isKillCounter, remainDiceRollChance, winnerId) = (
            result.battles.isEmpty == false,
            (self.currrentTurn?.remainRollChanceCount ?? 0) > 0,
            self.battleGround?.allKnightsOutPlayerId()
        )
        switch (isKillCounter, remainDiceRollChance, winnerId) {
        case (_, _, let .some(playerId)):
            let endEvent = GameEndEvent(winnerId: playerId)
            self.sendEvent(endEvent, after: previousEvent)
            
        case (true, _, _):
            self.updateGameTurn(after: previousEvent) { turn in
                return turn
                    |> \.remainRollChanceCount +~ result.battles.count
                    |> \.expireTime +~ 60
            }
            
        case (_, true, _): return
            
        default:
            guard let counter = self.gameInfo.players.filter ({ $0.userId != currentPlayerId }).first else { return }
            self.changeTurn(next: counter.userId, after: previousEvent)
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


private extension GameEvent {
    
    var consumeTimeout: TimeInterval {
        // TODO: 이벤트별로 정의 필요
        return 3
    }
}
