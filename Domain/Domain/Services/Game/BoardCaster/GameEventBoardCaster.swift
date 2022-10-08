//
//  GameEventBoardCaster.swift
//  Domain
//
//  Created by sudo.park on 2022/10/08.
//

import Foundation
import Combine


public enum GameEventAfter {
    case ack(_ ackEventId: String, waitTimeout: TimeInterval)
}

public protocol GameEventBroadCaster: AnyObject, Sendable {
    
    func sendAck(_ ackEvent: GameAckEvent)
    func sendEvent(_ event: GameEvent, after: GameEventAfter?)
    
    var gameEvents: AnyPublisher<GameEvent, Never> { get }
}

extension GameEventBroadCaster {
    
    func sendEvent(_ event: GameEvent) {
        self.sendEvent(event, after: nil)
    }
}
