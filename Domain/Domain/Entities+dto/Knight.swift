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
