//
//  knight.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation
import Prelude
import Optics


public struct Knight: Equatable, Sendable {
    
    public let playerId: String
    public let id: String
    public var isDefence: Bool = false
    
    public init(
        playerId: String,
        isDefence: Bool
    ) {
        self.playerId = playerId
        self.id = UUID().uuidString
        self.isDefence = isDefence
    }
}

public typealias Knights = [Knight]

extension Knights {
    
    public var remainLifeCount: Int {
        let defenderCount = self.filter { $0.isDefence == true }.count
        let nonDefenderCount = self.filter { $0.isDefence == false }.count
        return nonDefenderCount != 0 && defenderCount != 0 ? 2 : 1
    }
    
    func attack(to other: Knights, at node: Node) -> Battle {
        let defenders = other.filter { $0.isDefence }
        let killed = defenders.isEmpty ? other : defenders
        let killedIds = Set(killed.map { $0.id })
        let surviver = other.filter { !killedIds.contains($0.id) }
        return Battle(
            at: node,
            killer: self,
            killed: killed,
            survived: surviver
        )
    }
}


public struct KnightPosition: Equatable, Sendable {
    
    public let knight: Knights
    public let current: Node
    public var comesFrom: Set<Node>?
    
    init(
        _ knight: Knights,
        at current: Node
    ) {
        self.knight = knight
        self.current = current
    }
    
    init?(knights: Knights, from: KnightMovePath.PathPerDice) {
        guard let dest = from.nodes.last else { return nil }
        self.knight = knights
        self.current = dest
        self.comesFrom = from.nodes[safe: from.nodes.count-2].map { Set([$0]) }
    }
    
    func merge(with other: KnightPosition) -> KnightPosition {
        let newComeFrom = (self.comesFrom ?? []) <> (other.comesFrom ?? [])
        return .init(self.knight + other.knight, at: self.current)
            |> \.comesFrom .~ (newComeFrom.isEmpty ? nil : newComeFrom)
    }
}


public struct KnightMovement: Equatable, Sendable {
    
    public let knights: Knights
    public let path: KnightMovePath
}
