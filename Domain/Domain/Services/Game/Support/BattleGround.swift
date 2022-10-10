//
//  BattleGround.swift
//  Domain
//
//  Created by sudo.park on 2022/09/12.
//

import Foundation
import Prelude
import Optics


struct BattleGround {
    
    var knightPositions: [KnightPosition] = []
    
    typealias MoveResult = (moves: [KnightsSingleMovement], battles: [Battle], finalPosition: KnightPosition)
    
    init(gameInfo: GameInfo) {
        self.knightPositions = gameInfo.knights.values
            .flatMap { $0 }
            .map { KnightPosition([$0], at: .start) }
    }
}


extension BattleGround {

    mutating func moveKnight(_ knightIds: [String], through path: KnightMovePath) -> MoveResult? {
        let positions = self.knightPositions
        let knightsMap = self.knightPositions.flatMap { $0.knight }
            .reduce(into: [String: Knight]()) { $0[$1.id] = $1 }
        let knights = knightIds.compactMap{ knightsMap[$0] }
        
        guard knights.count == knightIds.count,
              let startNode = path.start
        else {
            return nil
        }
        
        let initial = MoveResult([], [], .init(knights, at: startNode))
        let runMove: (MoveResult, KnightMovePath.PathPerDice) -> MoveResult = { totalResult, path in
            guard let result = self.moveKnight(
                positions: positions,
                from: totalResult.finalPosition,
                through: path
            )
            else { return totalResult }
            return (
                totalResult.0 + [result.0],
                totalResult.1 + (result.1.map { [$0] } ?? []),
                result.2
            )
        }
        let moveResult = path.serialPaths.reduce(initial, runMove)
        self.updateKnightPositions(by: moveResult, positions: positions)
        return moveResult
    }
    
    private func moveKnight(
        positions: [KnightPosition],
        from: KnightPosition,
        through path: KnightMovePath.PathPerDice
    ) -> (KnightsSingleMovement, Battle?, KnightPosition)? {
        guard let dest = path.nodes.last,
              let playerId = from.knight.first?.playerId,
              let movedPosition = KnightPosition(knights: from.knight, from: path)
        else { return nil }
        let knightPositionsAtDest = positions.filter { $0.current == dest }
        let (alliance, enemy) = (
            knightPositionsAtDest.filter { $0.knight.first?.playerId == playerId },
            knightPositionsAtDest.filter { $0.knight.first?.playerId != playerId }
        )
        let move = KnightsSingleMovement(knights: from.knight, path: path, mergedWith: alliance.flatMap { $0.knight })
        let newPosition = alliance.mergeAll(movedPosition)
        let battle = enemy.isEmpty == false
            ? self.battle(at: dest, from.knight, enemy.flatMap { $0.knight }) : nil
        return (move, battle, newPosition)
    }
    
    private mutating func updateKnightPositions(by result: MoveResult, positions: [KnightPosition]) {
        
        let newPositions = self.knightPositions
            .reArrangeKilledAndMoved(by: result)
            .resetOutDefendersToStart()
        
        self.knightPositions = newPositions
    }
    
    func battle(at node: Node, _ attacker: Knights, _ other: Knights) -> Battle {
        let defenders = other.filter { $0.isDefence }
        let killed = defenders.isEmpty ? other : defenders
        let killedIds = Set(killed.map { $0.id })
        let surviver = other.filter { !killedIds.contains($0.id) }
        return Battle(
            at: node,
            killer: attacker,
            killed: killed,
            survived: surviver
        )
    }
}

extension BattleGround {
    
    func allKnightsOutPlayerId() -> PlayerId? {
        let outAttackKnights = self.knightPositions.filter { $0.current == .out }
            .flatMap { $0.knight }
            .filter { $0.isDefence == false }
        let playerIds = self.knightPositions.flatMap { $0.knight }.map { $0.playerId } |> Set.init
        let outAttackKnightsPerPlayer = playerIds.reduce([PlayerId: [Knight]]()) { acc, playerId in
            let playerKnights = outAttackKnights.filter { $0.playerId == playerId }
            return acc |> key(playerId) %~ { ($0 ?? []) + playerKnights }
        }
        return outAttackKnightsPerPlayer
            .filter { $0.value.count == 3 }
            .map { $0.key }
            .first
    }
}

private extension KnightPosition {
    
    func exculde(_ knightIds: Set<String>) -> KnightPosition? {
        let remainKnights = self.knight.filter { !knightIds.contains($0.id) }
        return remainKnights.isEmpty ? nil : (.init(remainKnights, at: self.current) |> \.comesFrom .~ self.comesFrom)
    }
}


private extension Array where Element == KnightPosition {
    
    func mergeAll(_ inital: KnightPosition) -> KnightPosition {
        return self.reduce(inital) { $0.merge(with: $1) }
    }
    
    func reArrangeKilledAndMoved(by result: BattleGround.MoveResult) -> Array {
        let (killed, movedIds) = (
            result.battles.flatMap { b in b.killed.map { $0 } },
            result.finalPosition.knight.map { $0.id }
        )
        let excludeIds = (killed.map { $0.id } + movedIds) |> Set.init
        let reArranged = self.compactMap { $0.exculde(excludeIds) }
        let killedResetPositions = killed.map { KnightPosition([$0], at: .start) }
     
        return reArranged + [result.finalPosition] + killedResetPositions
    }
    
    func resetOutDefendersToStart() -> Array {
        let outDefenders = self.filter { $0.current == .out }.flatMap { $0.knight }.filter { $0.isDefence }
        let outDefenderIds = outDefenders.map { $0.id } |> Set.init
        let outDefenderRemovedPoistions = self.compactMap { $0.exculde(outDefenderIds) }
        let outDefenderResetPoistions = outDefenders.map { KnightPosition([$0], at: .start) }
        return outDefenderRemovedPoistions + outDefenderResetPoistions
    }
}
