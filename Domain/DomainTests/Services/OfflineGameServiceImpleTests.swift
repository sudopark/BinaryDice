//
//  OfflineGameServiceImpleTests.swift
//  DomainTests
//
//  Created by sudo.park on 2022/09/11.
//

import XCTest

import Combine
import Prelude
import Optics
import Extensions

@testable import Domain


class OfflineGameServiceImpleTests: XCTestCase {
    
    private var player1: Player {
        return Player(userId: "p:1", nickName: "player 1")
    }
    
    private var player2: Player {
        return Player(userId: "p:2", nickName: "player 2")
    }
    
    private var player1Knights: [Knight]!
    
    private var player2Knights: [Knight]!
    
    private var mockDiceRoller: MockDiceRoller!
    private var service: OfflineGameServiceImple!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        self.cancellables = []
        self.player1Knights = (0..<4).map { .init(playerId: "p:1", isDefence: $0 == 4) }
        self.player2Knights = (0..<4).map { .init(playerId: "p:2", isDefence: $0 == 4) }
        let gameInfo = GameInfo(
            gameId: "some",
            players: [self.player1, self.player2],
            knights: [self.player1.userId: self.player1Knights, self.player2.userId: self.player2Knights]
        )
        self.mockDiceRoller = .init()
        self.service = .init(gameInfo, diceRoller: mockDiceRoller)
    }
    
    override func tearDownWithError() throws {
        self.cancellables.forEach { $0.cancel() }
        self.cancellables = nil
        self.player1Knights = nil
        self.player2Knights = nil
        self.mockDiceRoller = nil
        self.service = nil
    }
}


extension OfflineGameServiceImpleTests {
    
    // 게임 시작 이후에 게임턴 이벤트 방출
    func testService_whenAfterGameStart_emitFirstGameTurnEvent() {
        // given
        let expect = expectation(description: "게임 시작 이후에 첫번째 턴 이벤트 방출")
        expect.expectedFulfillmentCount = 2
        
        // when
        let events = self.waitPublishedValues(expect, self.service.gameEvents) {
            self.service.enterGame(self.player1)
            self.service.enterGame(self.player2)
        }
        // then
        let startEvent = events[safe: 0] as? GameStartEvent
        let turnEvent = events[safe: 1] as? GameTurnChangeEvent
        XCTAssertNotNil(startEvent)
        XCTAssertNotNil(turnEvent)
    }
    
    // TODO: 이미 시작한 이후에 플레이어 다 들어와도 게임시작 이벤트 방출 안함
}

extension OfflineGameServiceImpleTests {
    
    private func setupGameStart() {
        let expect = expectation(description: "wait for start game")
        expect.expectedFulfillmentCount = 2
        
        let _ = self.waitPublishedValues(expect, self.service.gameEvents) {
            self.service.enterGame(self.player1)
            self.service.enterGame(self.player2)
        }
    }
    
    // 턴인 유저가 주사위 굴림 -> 굴린 결과 이벤트 방출
    func testService_whenAfterRollDice_emitRollEvent() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "주사위 굴린 이후에 주사위 굴림 이벤트 전파")
        expect.assertForOverFulfill = false
        
        // when
        let event = self.waitFirstPublishedValue(expect, self.service.gameEvents) {
            self.service.rollDice(self.player1.userId)
        }
        
        // then
        let diceEfvent = event as? RollDiceEvent
        XCTAssertNotNil(diceEfvent)
    }
    
    
    // 턴이 아닌 유저가 주사위 굴리면 무시
    func testService_whenRollDiceRequestedFromNotTurnPlayer_ignore() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "현재 턴이 아닌 유저가 주사위 굴릴시 무시")
        expect.isInverted = true
        
        // when
        let event = self.waitFirstPublishedValue(expect, self.service.gameEvents) {
            self.service.rollDice(self.player2.userId)
        }
        
        // then
        XCTAssertNil(event)
    }
    
    // 주사위 굴리면 턴 정보 업데이트
    func testService_whenAfterRollDice_alsoUpdateTurnUpdatedEvent() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "주사위 던진 이후에 턴정보도 업데이트됨")
        expect.expectedFulfillmentCount = 2
        
        // when
        let events = self.waitPublishedValues(expect, self.service.gameEvents) {
            self.mockDiceRoller.mocking = .gul
            self.service.rollDice(self.player1.userId)
        }
        
        // then
        let diceEvent = events[safe: 0] as? RollDiceEvent
        let updatedEvent = events[safe: 1] as? GameTurnUpdateEvent
        XCTAssertNotNil(diceEvent)
        XCTAssertEqual(updatedEvent?.turn.playerId, self.player1.userId)
        XCTAssertEqual(updatedEvent?.turn.remainRollChangeCount, 0)
        XCTAssertEqual(updatedEvent?.turn.pendingRollsForMove, [.gul])
    }
    
    // 주사위 굴리고 윷이랑 모 나오면 턴정보에서 remainRoll 카운트 안깍김
    func testService_whenAfterRollYutOrMo_notDecreaseRemainRollCountOnTurnInfo() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "윷이나 모 나오면 남은 롤카운트 안줄어들음")
        expect.expectedFulfillmentCount = 4
        
        // when
        let events = self.waitPublishedValues(expect, self.service.gameEvents) {
            self.mockDiceRoller.mocking = .yut
            self.service.rollDice(self.player1.userId)
            
            self.mockDiceRoller.mocking = .mo
            self.service.rollDice(self.player1.userId)
        }
        
        // then
        let rollEvent1 = events[safe: 0] as? RollDiceEvent
        let updateEvent1 = events[safe: 1] as? GameTurnUpdateEvent
        let rollEvent2 = events[safe: 2] as? RollDiceEvent
        let updateEvent2 = events[safe: 3] as? GameTurnUpdateEvent
        XCTAssertEqual(rollEvent1?.result, .yut)
        XCTAssertEqual(updateEvent1?.turn.remainRollChangeCount, 1)
        XCTAssertEqual(updateEvent1?.turn.pendingRollsForMove, [.yut])
        XCTAssertEqual(rollEvent2?.result, .mo)
        XCTAssertEqual(updateEvent2?.turn.remainRollChangeCount, 1)
        XCTAssertEqual(updateEvent2?.turn.pendingRollsForMove, [.yut, .mo])
    }
    
    // 주사위 굴리고 결과에 따라 말 움직임 -> 점령정보 변경 이벤트 전파
    func testService_whenAfterRolLAndMove_updateOccupationInfo() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "주사위 굴리고 + 말 이동한 이후에 점령정보 업데이트됨")
        expect.expectedFulfillmentCount = 2
        expect.assertForOverFulfill = false
        
        // when
        let events = self.waitPublishedValues(expect, self.service.gameEvents.dropFirst(2)) {
            self.mockDiceRoller.mocking = .yut
            self.service.rollDice(self.player1.userId)
            self.service.moveKnight([self.player1Knights.first!.id], at: .init(serialPaths: [
                [.start, .R1, .R2, .R3, .R4]
            ]))
        }
        
        // then
        let occupationEvent = events[safe: 0] as? NodeOccupationUpdateEvent
        let updateEvent = events[safe: 1] as? GameTurnUpdateEvent
        XCTAssertEqual(occupationEvent?.knightPositions, [
            .init([self.player1Knights.first!], at: .R4) |> \.comesFrom .~ [.R3]
        ])
        XCTAssertEqual(updateEvent?.turn.pendingRollsForMove, [])
        XCTAssertEqual(updateEvent?.turn.remainRollChangeCount, 1)
    }
    
    // 말 이동 이후에 더이상 던질거 없으면 턴변경 이벤트 전파
    func testService_whenAfterMoveKnightAndremainRollCountisZero_changeTurn() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "말 이동시킨 이후에 더이상 던질 주사위 없으면 턴 변경")
        expect.expectedFulfillmentCount = 2
        
        // when
        let events = self.waitPublishedValues(expect, service.gameEvents.dropFirst(2)) {
            self.mockDiceRoller.mocking = .gae
            self.service.rollDice(self.player1.userId)
            self.service.moveKnight([self.player1Knights.first!.id], at: .init(serialPaths: [
                [.start, .R1, .R2]
            ]))
        }
        
        // then
        let occupationEvent = events[safe: 0] as? NodeOccupationUpdateEvent
        let changeEvent = events[safe: 1] as? GameTurnChangeEvent
        XCTAssertNotNil(occupationEvent)
        XCTAssertEqual(changeEvent?.turn.playerId, self.player2.userId)
    }
}

extension OfflineGameServiceImpleTests {
    
    private func movePlayer1KnightAtR2() {
        self.setupGameStart()
        let expect = expectation(description: "턴 변경시까지 대기")
        expect.assertForOverFulfill = false
        
        let turnChanged = service.gameEvents
            .compactMap { $0 as? GameTurnChangeEvent }
            .filter { $0.turn.playerId == self.player2.userId }
        
        let _ = self.waitFirstPublishedValue(expect, turnChanged) {
            self.mockDiceRoller.mocking = .gae
            self.service.rollDice(self.player1.userId)
            self.service.moveKnight([self.player1Knights.first!.id], at: .init(serialPaths: [
                [.start, .R1, .R2]
            ]))
        }
        self.wait(for: [expect], timeout: 0.001)
    }
    
    // 말 하나 잡으면 턴정보 업데이트(롤카운트 +1)
    func testService_whenKillKnight_increaseRollCount() {
        // given
        self.movePlayer1KnightAtR2()
        let expect = expectation(description: "상대말 잡고 턴 업데이트")
        expect.expectedFulfillmentCount = 4
        
        // when
        let events = self.waitPublishedValues(expect, service.gameEvents) {
            self.mockDiceRoller.mocking = .gae
            self.service.rollDice(self.player2.userId)  // dice roll event + turn update event
            self.service.moveKnight([self.player2Knights.first!.id], at: .init(serialPaths: [
                [.start, .R1, .R2]
            ]))   // occupation update event + turn update
        }
        
        // then
        let rollUpdateEvent = events[safe: 0] as? RollDiceEvent
        let turnUpdateEvent = events[safe: 1] as? GameTurnUpdateEvent
        let occupationUpdateEvent = events[safe: 2] as? NodeOccupationUpdateEvent
        let turnUpdateAgainEvent = events[safe: 3] as? GameTurnUpdateEvent
        XCTAssertEqual(rollUpdateEvent?.playerId, self.player2.userId)
        XCTAssertEqual(rollUpdateEvent?.result, .gae)
        XCTAssertEqual(turnUpdateEvent?.turn.playerId, self.player2.userId)
        XCTAssertEqual(turnUpdateEvent?.turn.pendingRollsForMove, [.gae])
        XCTAssertEqual(turnUpdateEvent?.turn.remainRollChangeCount, 0)
        XCTAssertEqual(occupationUpdateEvent?.movemensts, [.init(knights: [self.player2Knights.first!], path: .init(serialPaths: [
            [.start, .R1, .R2]
        ]))])
        XCTAssertEqual(occupationUpdateEvent?.battles, [.init(at: .R2, killed: [self.player1Knights.first!])])
        XCTAssertEqual(occupationUpdateEvent?.knightPositions, [
            .init([self.player2Knights.first!], at: .R2) |> \.comesFrom .~ [.R1]
        ])
        XCTAssertEqual(turnUpdateAgainEvent?.turn.pendingRollsForMove, [])
        XCTAssertEqual(turnUpdateAgainEvent?.turn.remainRollChangeCount, 1)
    }
    
    // 선택한 경로 이동중에 상대말 있으면 잡음 -> 점령 정보에 배틀정보 있음
    func testService_whenOtherKnightIsOnthePath_kill() {
        // given
        self.movePlayer1KnightAtR2()
        let expect = expectation(description: "이동 경로 목적지 중에 상대말 있으면 죽임")
        
        // when
        let occupationEvent = service.gameEvents.compactMap { $0 as? NodeOccupationUpdateEvent }
        let event = self.waitFirstPublishedValue(expect, occupationEvent) {
            self.mockDiceRoller.mocking = .yut
            self.service.rollDice(self.player2.userId)
            self.mockDiceRoller.mocking = .gae
            self.service.rollDice(self.player2.userId)
            self.service.moveKnight([self.player2Knights.first!.id], at: .init(serialPaths: [
                [.start, .R1, .R2], [.R2, .R3, .R4, .CTR, .T1]
            ]))
        }
        
        // then
        XCTAssertEqual(event?.battles, [.init(at: .R2, killed: [self.player1Knights.first!])])
        XCTAssertEqual(event?.movemensts, [
            .init(knights: [self.player2Knights.first!], path: .init(serialPaths: [
                [.start, .R1, .R2], [.R2, .R3, .R4, .CTR, .T1]
            ]))
        ])
        XCTAssertEqual(event?.knightPositions, [.init([self.player2Knights.first!], at: .T1)])
    }
    
    // 같은편 말 합체
    func testService_whenSameSideKnightOnDestination_mergeKnights() {
        // given
        self.movePlayer1KnightAtR2()
        let expect = expectation(description: "같은 편 말이 목적지에 위치하면 합체")
        expect.expectedFulfillmentCount = 2
        
        // when
        let occupationEvent = service.gameEvents.compactMap { $0 as? NodeOccupationUpdateEvent }
        let events = self.waitPublishedValues(expect, occupationEvent) {
            self.mockDiceRoller.mocking = .yut
            self.service.rollDice(self.player2.userId)
            self.service.moveKnight([self.player2Knights.first!.id], at: .init(serialPaths: [
                [.start, .R1, .R2, .R3, .R4]
            ]))
            
            self.mockDiceRoller.mocking = .yut
            self.service.rollDice(self.player2.userId)
            self.service.moveKnight([self.player2Knights.last!.id], at: .init(serialPaths: [
                [.start, .R1, .R2, .R3, .R4]
            ]))
        }
        // then
        let (event1, event2) = (events[safe: 0], events[safe: 1])
        XCTAssertEqual(event1?.battles, [])
        XCTAssertEqual(event1?.movemensts, [
            .init(knights: [self.player2Knights.first!], path: .init(serialPaths: [
                [.start, .R1, .R2, .R3, .R4]
            ]))
        ])
        XCTAssertEqual(event1?.knightPositions, [
            .init([self.player2Knights.first!], at: .R4) |> \.comesFrom .~ [.R3]
        ])
        XCTAssertEqual(event2?.battles, [])
        XCTAssertEqual(event2?.movemensts, [
            .init(knights: [self.player2Knights.last!], path: .init(serialPaths: [
                [.start, .R1, .R2, .R3, .R4]
            ]))
        ])
        XCTAssertEqual(event2?.knightPositions, [
            .init([self.player2Knights.first!, self.player2Knights.last!], at: .R4) |> \.comesFrom .~ [.R3]
        ])
    }
    
    // 이동 경로 목적지 중에 같은편말 있으면 합체
    func testService_whenSameSideKnightOnOneOfDestinationAtPath_mergeKnights() {
        // given
        self.movePlayer1KnightAtR2()
        let expect = expectation(description: "같은 편 말이 경로상 중간목적지 중 에 위치하면 합체")
        expect.expectedFulfillmentCount = 2
        
        // when
        let occupationEvent = service.gameEvents.compactMap { $0 as? NodeOccupationUpdateEvent }
        let events = self.waitPublishedValues(expect, occupationEvent) {
            self.mockDiceRoller.mocking = .yut
            self.service.rollDice(self.player2.userId)
            self.service.moveKnight([self.player2Knights.first!.id], at: .init(serialPaths: [
                [.start, .R1, .R2, .R3, .R4]
            ]))
            
            self.mockDiceRoller.mocking = .yut
            self.service.rollDice(self.player2.userId)
            
            self.mockDiceRoller.mocking = .gae
            self.service.rollDice(self.player2.userId)
            
            self.service.moveKnight([self.player2Knights.last!.id], at: .init(serialPaths: [
                [.start, .R1, .R2, .R3, .R4], [.R4, .CTR, .T1]
            ]))
        }
        // then
        let (event1, event2) = (events[safe: 0], events[safe: 1])
        XCTAssertEqual(event1?.battles, [])
        XCTAssertEqual(event1?.movemensts, [
            .init(knights: [self.player2Knights.first!], path: .init(serialPaths: [
                [.start, .R1, .R2, .R3, .R4]
            ]))
        ])
        XCTAssertEqual(event1?.knightPositions, [
            .init([self.player2Knights.first!], at: .R4) |> \.comesFrom .~ [.R3]
        ])
        XCTAssertEqual(event2?.battles, [])
        XCTAssertEqual(event2?.movemensts, [
            .init(knights: [self.player2Knights.last!], path: .init(serialPaths: [
                [.start, .R1, .R2, .R3, .R4]
            ])),
            .init(knights: [self.player2Knights.first!, self.player2Knights.last!], path: .init(serialPaths: [
                [.R4, .CTR, .T1]
            ]))
        ])
        XCTAssertEqual(event2?.knightPositions, [
            .init([self.player2Knights.first!, self.player2Knights.last!], at: .R4) |> \.comesFrom .~ [.R3]
        ])
    }
    
    // TODO: 세부 싸움 정책 테스트 -> knight
    
    // 공격말 vs 공격말 -> 공격한쪽이 이김
    
    // 공격말 vs [공격말] -> 공격한쪽이 이김
    
    // 수비말 vs 공격말 -> 수비말이 이김
    
    // 수비말 vs [공격말] -> 수비말이 이김
    
    // 수비말 vs 수비말 -> 공격한쪽이 이김
    
    // 수비말 vs [수비 + 공격말] -> 수비말만 죽음
    
    // 공격말은 잡은 수 x 10 만큼 점수를 획득
    
    // 수비말은 잡은 수 x 15 만큼 점수를 획득
}

extension OfflineGameServiceImpleTests {
    
    // 공격말이 모두 나가면 50 포인트 획득
    
    // 공격말이 모두 나가면 점수 합산해서 승자 판단
}


private extension OfflineGameServiceImpleTests {
    
    
    func waitPublishedValues<P: Publisher>(
        _ expect: XCTestExpectation,
        _ publisher: P,
        _ action: (() -> Void)? = nil
    ) -> [P.Output] {
        
        var sender = [P.Output]()
        
        publisher
            .sink { _ in } receiveValue: {
                sender.append($0)
                expect.fulfill()
            }
            .store(in: &self.cancellables)
        
        action?()
        self.wait(for: [expect], timeout: 0.001)
        
        return sender
    }
    
    func waitFirstPublishedValue<P: Publisher>(
        _ expect: XCTestExpectation,
        _ publisher: P,
        _ action: (() -> Void)? = nil
    ) -> P.Output? {
        return self.waitPublishedValues(expect, publisher, action).first
    }
}


private extension OfflineGameServiceImpleTests {
    
    class MockDiceRoller: RandDomiceRoller, @unchecked Sendable {
        
        var mocking: BinaryDice = .gae
        
        func roll() -> BinaryDice {
            return self.mocking
        }
    }
}
