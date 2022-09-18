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
import TestHelpKit
import AsyncAlgorithms

@testable import Domain


class OfflineGameServiceImpleTests: BaseTestCase, PublishedValueWaitAndTestable {
    
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
    public var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        self.cancellables = []
        self.player1Knights = (0..<4).map { .init(playerId: "p:1", isDefence: $0 == 3) }
        self.player2Knights = (0..<4).map { .init(playerId: "p:2", isDefence: $0 == 3) }
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
        expect.assertForOverFulfill = false
        
        let _ = self.waitPublishedValues(expect, self.service.gameEvents.prefix(2)) {
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
            Task { try await self.service.rollDice(self.player1.userId) }
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
            Task { try await self.service.rollDice(self.player2.userId) }
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
            Task { try await self.service.rollDice(self.player1.userId) }
        }
        
        // then
        let diceEvent = events[safe: 0] as? RollDiceEvent
        let updatedEvent = events[safe: 1] as? GameTurnUpdateEvent
        XCTAssertNotNil(diceEvent)
        XCTAssertEqual(updatedEvent?.turn.playerId, self.player1.userId)
        XCTAssertEqual(updatedEvent?.turn.remainRollChanceCount, 0)
        XCTAssertEqual(updatedEvent?.turn.pendingRollsForMove, [.gul: 1])
    }
    
    // 주사위 굴리고 윷이랑 모 나오면 턴정보에서 remainRoll 카운트 안깍김
    func testService_whenAfterRollYutOrMo_notDecreaseRemainRollCountOnTurnInfo() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "윷이나 모 나오면 남은 롤카운트 안줄어들음")
        expect.expectedFulfillmentCount = 4
        
        // when
        let events = self.waitPublishedValues(expect, self.service.gameEvents) {
            Task {
                self.mockDiceRoller.mocking = .yut
                try await self.service.rollDice(self.player1.userId)
                
                self.mockDiceRoller.mocking = .mo
                try await self.service.rollDice(self.player1.userId)
            }
        }
        
        // then
        let rollEvent1 = events[safe: 0] as? RollDiceEvent
        let updateEvent1 = events[safe: 1] as? GameTurnUpdateEvent
        let rollEvent2 = events[safe: 2] as? RollDiceEvent
        let updateEvent2 = events[safe: 3] as? GameTurnUpdateEvent
        XCTAssertEqual(rollEvent1?.result, .yut)
        XCTAssertEqual(updateEvent1?.turn.remainRollChanceCount, 1)
        XCTAssertEqual(updateEvent1?.turn.pendingRollsForMove, [.yut: 1])
        XCTAssertEqual(rollEvent2?.result, .mo)
        XCTAssertEqual(updateEvent2?.turn.remainRollChanceCount, 1)
        XCTAssertEqual(updateEvent2?.turn.pendingRollsForMove, [.yut: 1, .mo: 1])
    }
    
    // 주사위 굴리고 결과에 따라 말 움직임 -> 점령정보 변경 이벤트 전파
    func testService_whenAfterRolLAndMove_updateOccupationInfo() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "주사위 굴리고 + 말 이동한 이후에 점령정보 업데이트됨")
        expect.expectedFulfillmentCount = 3
        expect.assertForOverFulfill = false
        
        // when
        let events = self.waitPublishedValues(expect, self.service.gameEvents.dropFirst(1)) {
            Task {
                self.mockDiceRoller.mocking = .yut
                try await self.service.rollDice(self.player1.userId)
                try await self.service.moveKnight(
                    self.player1.userId,
                    [self.player1Knights.first!.id],
                    through: .init(serialPaths: [.init(.yut, [.start, .R1, .R2, .R3, .R4])])
                )
            }
        }
        
        // then
        let updateEventAferDice = events[safe: 0] as? GameTurnUpdateEvent
        let updateEventAfterMove = events[safe: 1] as? GameTurnUpdateEvent
        let occupationEvent = events[safe: 2] as? NodeOccupationUpdateEvent
    
        XCTAssertEqual(updateEventAferDice?.turn.sequeceId, 0)
        XCTAssertEqual(updateEventAferDice?.turn.playerId, self.player1.userId)
        XCTAssertEqual(updateEventAferDice?.turn.remainRollChanceCount, 1)
        XCTAssertEqual(updateEventAferDice?.turn.pendingRollsForMove, [.yut: 1])
        
        XCTAssertEqual(updateEventAfterMove?.turn.sequeceId, 0)
        XCTAssertEqual(updateEventAfterMove?.turn.playerId, self.player1.userId)
        XCTAssertEqual(updateEventAfterMove?.turn.remainRollChanceCount, 1)
        XCTAssertEqual(updateEventAfterMove?.turn.pendingRollsForMove, [:])
        
        let position = occupationEvent?.knightPositions.position(for: self.player1Knights.first!.id)
        XCTAssertEqual(position, .init([self.player1Knights.first!], at: .R4) |> \.comesFrom .~ [.R3])
    }
    
    // 말 이동 이후에 더이상 던질거 없으면 턴변경 이벤트 전파
    func testService_whenAfterMoveKnightAndremainRollCountisZero_changeTurn() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "말 이동시킨 이후에 더이상 던질 주사위 없으면 턴 변경")
        expect.expectedFulfillmentCount = 3
        
        // when
        let events = self.waitPublishedValues(expect, service.gameEvents.dropFirst(2)) {
            Task {
                self.mockDiceRoller.mocking = .gae
                try await self.service.rollDice(self.player1.userId)
                try await self.service.moveKnight(
                    self.player1.userId,
                    [self.player1Knights.first!.id],
                    through: .init(serialPaths: [.init(.gae, [.start, .R1, .R2])])
                )
            }
        }
        
        // then
        let updateEventAfterMove = events[safe: 0] as? GameTurnUpdateEvent
        let occupationEvent = events[safe: 1] as? NodeOccupationUpdateEvent
        let changeEvent = events[safe: 2] as? GameTurnChangeEvent
        XCTAssertEqual(updateEventAfterMove?.turn.sequeceId, 0)
        XCTAssertEqual(updateEventAfterMove?.turn.playerId, self.player1.userId)
        
        let position = occupationEvent?.knightPositions.position(for: self.player1Knights.first!.id)
        XCTAssertEqual(position, .init([self.player1Knights.first!], at: .R2) |> \.comesFrom .~ [.R1])
        
        XCTAssertEqual(changeEvent?.turn.sequeceId, 1)
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
            Task {
                self.mockDiceRoller.mocking = .gae
                try await self.service.rollDice(self.player1.userId)
                try await self.service.moveKnight(
                    self.player1.userId,
                    [self.player1Knights.first!.id],
                    through: .init(serialPaths: [.init(.gae, [.start, .R1, .R2])])
                )
            }
        }
    }
    
    // 말 하나 잡으면 턴정보 업데이트(롤카운트 +1)
    func testService_whenKillKnight_increaseRollCount() {
        // given
        self.movePlayer1KnightAtR2()
        let expect = expectation(description: "상대말 잡고 턴 업데이트")
        expect.expectedFulfillmentCount = 5
        
        // when
        let events = self.waitPublishedValues(expect, service.gameEvents) {
            Task {
                self.mockDiceRoller.mocking = .gae
                try await self.service.rollDice(self.player2.userId)  // dice roll event + turn update event
                
                try await self.service.moveKnight(
                    self.player2.userId,
                    [self.player2Knights.first!.id],
                    through: .init(serialPaths: [.init(.gae, [.start, .R1, .R2])])
                )   // occupation update event + turn update
            }
        }
        
        // then
        let rollUpdateEvent = events[safe: 0] as? RollDiceEvent
        let turnUpdateEvent = events[safe: 1] as? GameTurnUpdateEvent
        let turnUpdateEventAfterMove = events[safe: 2] as? GameTurnUpdateEvent
        let occupationUpdateEvent = events[safe: 3] as? NodeOccupationUpdateEvent
        let turnUpdateAgainEvent = events[safe: 4] as? GameTurnUpdateEvent
        XCTAssertEqual(rollUpdateEvent?.playerId, self.player2.userId)
        XCTAssertEqual(rollUpdateEvent?.result, .gae)
        
        XCTAssertEqual(turnUpdateEvent?.turn.sequeceId, 1)
        XCTAssertEqual(turnUpdateEvent?.turn.playerId, self.player2.userId)
        XCTAssertEqual(turnUpdateEvent?.turn.pendingRollsForMove, [.gae: 1])
        XCTAssertEqual(turnUpdateEvent?.turn.remainRollChanceCount, 0)
        
        XCTAssertEqual(turnUpdateEventAfterMove?.turn.sequeceId, 1)
        XCTAssertEqual(turnUpdateEventAfterMove?.turn.pendingRollsForMove, [:])
        XCTAssertEqual(turnUpdateEventAfterMove?.turn.remainRollChanceCount, 0)
        
        let positionKn1 = occupationUpdateEvent?.knightPositions.position(for: self.player1Knights.first!.id)
        let positionKn2 = occupationUpdateEvent?.knightPositions.position(for: self.player2Knights.first!.id)
        XCTAssertEqual(positionKn1?.current, .start)
        XCTAssertEqual(positionKn2?.current, .R2)
        XCTAssertEqual(occupationUpdateEvent?.battles.isEmpty, false)
        
        XCTAssertEqual(turnUpdateAgainEvent?.turn.sequeceId, 1)
        XCTAssertEqual(turnUpdateAgainEvent?.turn.playerId, self.player2.userId)
        XCTAssertEqual(turnUpdateAgainEvent?.turn.pendingRollsForMove, [:])
        XCTAssertEqual(turnUpdateAgainEvent?.turn.remainRollChanceCount, 1)
    }
    
    // 선택한 경로 이동중에 상대말 있으면 잡음 -> 점령 정보에 배틀정보 있음
    func testService_whenOtherKnightIsOnthePath_kill() {
        // given
        self.movePlayer1KnightAtR2()
        let expect = expectation(description: "이동 경로 목적지 중에 상대말 있으면 죽임")
        
        // when
        let occupationEvent = service.gameEvents.compactMap { $0 as? NodeOccupationUpdateEvent }
        let event = self.waitFirstPublishedValue(expect, occupationEvent) {
            Task {
                self.mockDiceRoller.mocking = .yut
                try await self.service.rollDice(self.player2.userId)
                self.mockDiceRoller.mocking = .gae
                try await self.service.rollDice(self.player2.userId)
                try await self.service.moveKnight(
                    self.player2.userId,
                    [self.player2Knights.first!.id],
                    through: .init(serialPaths: [
                        .init(.gae, [.start, .R1, .R2]), .init(.yut, [.R2, .R3, .R4, .CTR, .T1])
                    ])
                )
            }
        }
        
        // then
        XCTAssertEqual(event?.battles, [
            .init(at: .R2, killer: [self.player2Knights.first!], killed: [self.player1Knights.first!], survived: [])
        ])
        XCTAssertEqual(event?.movemensts.count, 2)
        let positionK1 = event?.knightPositions.position(for: self.player1Knights.first!.id)
        let positionK2 = event?.knightPositions.position(for: self.player2Knights.first!.id)
        XCTAssertEqual(positionK1?.current, .start)
        XCTAssertEqual(positionK2?.current, .T1)
    }
    
    // 수비말은 out 하면 start로 다시 변경
    func testService_whenDefenderKnightOut_returnToStartPosition() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "수비말은 나가면 시작지점으로 원위치")
        
        let serialPath = KnightMovePath(serialPaths: [
            .init(.mo, [.start, .B4, .B3, .B2, .B1, .CBL]),
            .init(.mo, [.CBL, .L4, .L3, .L2, .L1, .CTL]),
            .init(.mo, [.CTL, .T4, .T3, .T2, .T1, .CTR]),
            .init(.mo, [.R4, .R3, .R2, .R1, .CBR]),
            .init(.gae, [.CBR, .out])
        ])
        
        // when
        let occupationEvent = self.service.gameEvents.compactMap { $0 as? NodeOccupationUpdateEvent }
        let event = self.waitFirstPublishedValue(expect, occupationEvent) {
            Task {
                self.mockDiceRoller.mocking = .mo
                for try await _ in (0..<4).async {
                    try await self.service.rollDice(self.player1.userId)
                }
                self.mockDiceRoller.mocking = .gae
                try await self.service.rollDice(self.player1.userId)
                
                try await self.service.moveKnight(
                    self.player1.userId,
                    [self.player1Knights.last!.id],
                    through: serialPath
                )
            }
        }
        
        // then
        XCTAssertEqual(event?.movemensts.count, 5)
        let defenderPosition = event?.knightPositions.position(for: self.player1Knights.last!.id)
        XCTAssertEqual(defenderPosition?.current, .start)
    }
}

extension OfflineGameServiceImpleTests {
    
    // 공격말 다 나가면 게임 끝남 -> 다 내보낸 이가 승자
    func testService_whenAllAttackKnightOut_gameEndAndIsWinner() {
        // given
        self.setupGameStart()
        let expect = expectation(description: "공격말이 다 나가면 게임끝나고 해당 유저가 승자")
        let paths: [KnightMovePath.PathPerDice] = [
            .init(.mo, [.start, .R1, .R2, .R3, .R4, .CTR]),
            .init(.gul, [.CTR, .DL1, .DL2, .INT]),
            .init(.yut, [.INT, .DR2, .DR3, .CBR, .out])
        ]
        
        // when
        let (skipDiceAndTurnUpdateCount, skipKnightMoveAndUpdateCount) = (3*2, 2)
        let totalSkipCount = skipDiceAndTurnUpdateCount + skipKnightMoveAndUpdateCount
        let events = self.waitPublishedValues(expect, self.service.gameEvents.dropFirst(totalSkipCount)) {
            Task {
                self.mockDiceRoller.mocking = .mo
                try await self.service.rollDice(self.player1.userId)
                self.mockDiceRoller.mocking = .yut
                try await self.service.rollDice(self.player1.userId)
                self.mockDiceRoller.mocking = .gul
                try await self.service.rollDice(self.player1.userId)
                
                try await self.service.moveKnight(
                    self.player1.userId,
                    self.player1Knights.enumerated().filter { $0.offset < 3}.map { $0.element.id },
                    through: .init(serialPaths: paths))
            }
        }
        
        // then
        let gameEndEvent = events.first as? GameEndEvent
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(gameEndEvent?.winnerId, self.player1.userId)
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

private extension Array where Element == KnightPosition {
    
    func position(for knightId: String) -> KnightPosition? {
        return self.first(where: { $0.knight.contains(where: { $0.id == knightId })})
    }
}
