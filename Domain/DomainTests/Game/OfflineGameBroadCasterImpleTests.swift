//
//  OfflineGameBroadCasterImpleTests.swift
//  DomainTests
//
//  Created by sudo.park on 2022/10/08.
//

import XCTest
import Combine
import TestHelpKit

@testable import Domain

class OfflineGameBroadCasterImpleTests: BaseTestCase, PublishedValueWaitAndTestable {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        self.timeout *= 10
        self.cancellables = []
    }
    
    override func tearDownWithError() throws {
        self.cancellables = nil
    }
    
    private var players: [Player] {
        return [
            .init(userId: "p1", nickName: "n1"),
            .init(userId: "p2", nickName: "n2")
        ]
    }
        
    private func makeBroadCaster() -> OfflineGameBroadCasterImple {
        return OfflineGameBroadCasterImple(self.players)
    }
    
    private func ackEvent(_ eventId: String, for playerId: String) -> GameAckEvent {
        return  .init(eventId: eventId, playerId: playerId)
    }
}


extension OfflineGameBroadCasterImpleTests {
    
    // 딜레이 없이 바로 이벤트 전송
    func testBroadcaster_sendEvent() {
        // given
        let expect = expectation(description: "딜레이 없이 이벤트 발송")
        let broadCaster = self.makeBroadCaster()
        let sendEvent = DummyEvent()
        
        // when
        let sentEvent = self.waitFirstPublishedValue(expect, broadCaster.gameEvents.filter { $0.uuid == sendEvent.uuid }) {
            broadCaster.sendEvent(sendEvent, after: nil)
        }
        
        // then
        XCTAssertNotNil(sentEvent)
    }
    
    // ack 다 받은 이후에 이벤트 전송
    func testBroadCaster_sendEventAfterAllAckReceived() {
        // given
        let expect = expectation(description: "ack 다 받은 이후에 이벤트 발송")
        let broadCaster = self.makeBroadCaster()
        let (event1, event2) = (DummyEvent(), DummyEvent())
        
        // when
        let event2Sent = self.waitFirstPublishedValue(expect, broadCaster.gameEvents.filter { $0.uuid == event2.uuid }) {
            
            broadCaster.sendEvent(event1)
            broadCaster.sendEvent(event2, after: .ack(event1.uuid, waitTimeout: self.timeout * 2))
            
            let ack1 = self.ackEvent(event1.uuid, for: self.players[0].userId)
            broadCaster.sendAck(ack1)
            
            let ack2 = self.ackEvent(event1.uuid, for: self.players[1].userId)
            broadCaster.sendAck(ack2)
        }
        
        // then
        XCTAssertNotNil(event2Sent)
    }
    
    // 지정된 ack 다 받을때까지 기다렸다가 이벤트 전송
    func testBroadCaster_sendEventAfterWaitingEventSentAndAllAckReceived() {
        // given
        let expect = expectation(description: "앞선 이벤트 전송되고 지정된 ack 다 받은 이후에 이벤트 발송")
        let broadCaster = self.makeBroadCaster()
        let (event1, event2, event3) = (DummyEvent(), DummyEvent(), DummyEvent())

        // when
        let event3Sent = self.waitFirstPublishedValue(expect, broadCaster.gameEvents.filter { $0.uuid == event3.uuid }) {

            broadCaster.sendEvent(event1)
            broadCaster.sendEvent(event2, after: .ack(event1.uuid, waitTimeout: self.timeout * 2))
            broadCaster.sendEvent(event3, after: .ack(event2.uuid, waitTimeout: self.timeout * 2))

            let event1Acks = self.players.map { GameAckEvent(eventId: event1.uuid, playerId: $0.userId) }
            event1Acks.forEach {
                broadCaster.sendAck($0)
            }
            
            let event2Acks = self.players.map { GameAckEvent(eventId: event2.uuid, playerId: $0.userId) }
            event2Acks.forEach {
                broadCaster.sendAck($0)
            }
        }

        // then
        XCTAssertNotNil(event3Sent)
    }
    
    // 지정된 ack 다 안들어와도 timout 이후에 이벤트 전송
    func testBroadcaster_whenNotAllAckReceived_sendMessageAfterTimeout() {
        // given
        let expect = expectation(description: "지정된 ack 다 안들어와도 timeout 이후에 이벤트 발송")
        let broadCaster = self.makeBroadCaster()
        let sendEvent = DummyEvent()
        
        // when
        let sentEvent = self.waitFirstPublishedValue(expect, broadCaster.gameEvents.filter { $0.uuid == sendEvent.uuid }) {
            
            broadCaster.sendEvent(sendEvent, after: .ack(sendEvent.uuid, waitTimeout: self.timeout/10))
            
            let ack1 = self.ackEvent(sendEvent.uuid, for: self.players[0].userId)
            broadCaster.sendAck(ack1)
        }
        
        // then
        XCTAssertNotNil(sentEvent)
    }
}

extension OfflineGameBroadCasterImpleTests {
    
    private struct DummyEvent: GameEvent {
        let uuid: String = UUID().uuidString
    }
}
