//
//  GameAckEvents.swift
//  Domain
//
//  Created by sudo.park on 2022/10/08.
//

import Foundation


public struct GameAckEvent {
    
    public let eventId: String
    public let playerId: String
    
    public init(eventId: String, playerId: String) {
        self.eventId = eventId
        self.playerId = playerId
    }
}
