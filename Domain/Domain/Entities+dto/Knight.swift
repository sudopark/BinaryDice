//
//  knight.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


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
    
    func fight(with other: Knights) -> Knights {
        let defenders = other.filter { $0.isDefence }
        return defenders.isEmpty ? other : defenders
    }
}


public struct KnightPosition: Equatable {
    
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
}
