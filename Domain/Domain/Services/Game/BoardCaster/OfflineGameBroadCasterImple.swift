//
//  OfflineGameBroadCasterImple.swift
//  Domain
//
//  Created by sudo.park on 2022/10/08.
//

import Foundation
import Combine
import Extensions
import Prelude
import Optics


public final class OfflineGameBroadCasterImple: GameEventBroadCaster, @unchecked Sendable {
    
    private let players: [Player]
    
    public init(_ players: [Player]) {
        self.players = players
    }

    private struct Subject {
        let sentEventIds = CurrentValueSubject<Set<String>, Never>([])
        let gameEvents = PassthroughSubject<GameEvent, Never>()
        let receivedAcks = CurrentValueSubject<[String: Set<PlayerId>], Never>([:])
    }
    private let subject = Subject()
    private var cancellables: Set<AnyCancellable> = []
}

extension OfflineGameBroadCasterImple {
    
    public func sendAck(_ ackEvent: GameAckEvent) {
        let newAcks = self.subject.receivedAcks.value
            |> key(ackEvent.eventId) %~ { $0 <> [ackEvent.playerId] }
        self.subject.receivedAcks.send(newAcks)
    }
    
    public func sendEvent(_ event: GameEvent, after: GameEventAfter?) {
        switch after {
        case .ack(let ackEventId, waitTimeout: let timeout):
            self.sendEventAfterAck(event, ackEventId: ackEventId, waitTimeout: timeout)
            
        case .none:
            self.sendEvent(event)
        }
    }
    
    private func sendEventAfterAck(
        _ event: GameEvent,
        ackEventId: String,
        waitTimeout: TimeInterval
    ) {
        
        let timeoutInt = Int(waitTimeout * 1000)
        
        let waitPreviousMessageSent = self.subject.sentEventIds
            .first(where: { $0.contains(ackEventId) })

        let previousMessageSentAndAllAck = waitPreviousMessageSent
            .flatMap { [weak self] _ -> AnyPublisher<Void, Never> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                return self.allAckReceived(ackEventId)
            }
        
        previousMessageSentAndAllAck
            .timeout(.milliseconds(timeoutInt), scheduler: DispatchQueue.main)
            .sink { [weak self] completed in
                guard case .finished = completed else { return }
                self?.sendEvent(event)
                
            } receiveValue: { _ in }
            .store(in: &self.cancellables)
    }
    
    private func allAckReceived(_ ackEventId: String) -> AnyPublisher<Void, Never> {
        
        let totalPlayerIds = self.players.map { $0.userId }.sorted()
        
        return self.subject.receivedAcks
            .compactMap { $0[ackEventId] }
            .first(where: { $0?.sorted() == totalPlayerIds })
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    private func sendEvent(_ event: GameEvent) {
        
        self.subject.gameEvents.send(event)
        
        let newSent = self.subject.sentEventIds.value <> [event.uuid]
        self.subject.sentEventIds.send(newSent)
    }
}

extension OfflineGameBroadCasterImple {
    
    public var gameEvents: AnyPublisher<GameEvent, Never> {
        return self.subject.gameEvents
            .eraseToAnyPublisher()
    }
}
