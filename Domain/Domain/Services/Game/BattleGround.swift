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
    
    typealias MoveResult = (moves: [KnightMovement], battles: [Battle], finalPosition: KnightPosition)
    
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
    ) -> (KnightMovement, Battle?, KnightPosition)? {
        guard let dest = path.nodes.last,
              let playerId = from.knight.first?.playerId,
              let movedPosition = KnightPosition(knights: from.knight, from: path)
        else { return nil }
        let knightPositionsAtDest = positions.filter { $0.current == dest }
        let (alliance, enemy) = (
            knightPositionsAtDest.filter { $0.knight.first?.playerId == playerId },
            knightPositionsAtDest.filter { $0.knight.first?.playerId != playerId }
        )
        let move = KnightMovement(knights: from.knight, path: .init(serialPaths: [path]))
        let newPosition = alliance.mergeAll(movedPosition)
        let battle = enemy.isEmpty == false
            ? from.knight.attack(to: enemy.flatMap { $0.knight }, at: dest)
            : nil
        return (move, battle, newPosition)
    }
    
    private mutating func updateKnightPositions(by result: MoveResult, positions: [KnightPosition]) {
        let (killed, movedIds) = (
            result.battles.flatMap { b in b.killed.map { $0 } },
            result.finalPosition.knight.map { $0.id }
        )
        let excludeIds = Set(killed.map { $0.id } + movedIds)
        let rearranged = positions.compactMap { $0.exculde(excludeIds) }
        let killedResetPositions = killed.map { KnightPosition([$0], at: .start) }
        
        let newPositions = rearranged + [result.finalPosition] + killedResetPositions
        self.knightPositions = newPositions
    }
}

private extension KnightPosition {
    
    func exculde(_ knightIds: Set<String>) -> KnightPosition? {
        let remainKnights = self.knight.filter { !knightIds.contains($0.id) }
        return remainKnights.isEmpty ? nil : .init(remainKnights, at: self.current)
    }
}


private extension Array where Element == KnightPosition {
    
    func mergeAll(_ inital: KnightPosition) -> KnightPosition {
        return self.reduce(inital) { $0.merge(with: $1) }
    }
}
