//
//  knight.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public struct Knight: Sendable {
    
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

public struct Knights {
    
    public let knights: [Knight]
    public var isDefence: Bool {
        return self.knights.first(where: { $0.isDefence }) != nil
    }
    
    public var remainLifeCount: Int {
        let defenderCount = knights.filter { $0.isDefence }.count
        let nonDefenderCount = knights.count - defenderCount
        return defenderCount + ((nonDefenderCount == 0) ? 0 : 1)
    }
}


public struct KnightPosition {
    
    let knight: Knights
    let current: Node
    var previousPositions: [Node]?
    
    init(
        _ knight: Knights,
        at current: Node
    ) {
        self.knight = knight
        self.current = current
    }
}
