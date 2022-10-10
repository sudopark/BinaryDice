//
//  BattleGroundTests.swift
//  DomainTests
//
//  Created by sudo.park on 2022/09/15.
//

import XCTest

import Prelude
import Optics
import Extensions

@testable import Domain


class BattleGroundTests: XCTestCase {
    
    private var gameInfo: GameInfo!
    private var ground: BattleGround!
    
    private func player1Knights(_ index: Int) -> Knight {
        return self.gameInfo.knights["p1"]![index]
    }
    
    private func player2Knights(_ index: Int) -> Knight {
        return self.gameInfo.knights["p2"]![index]
    }
    
    override func setUpWithError() throws {
        self.gameInfo = .init(
            gameId: "some",
            players: [
                .init(userId: "p1", nickName: "p1"),
                .init(userId: "p2", nickName: "p2")
            ],
            knights: [
                "p1": [
                    .init(playerId: "p1", isDefence: false),
                    .init(playerId: "p1", isDefence: false),
                    .init(playerId: "p1", isDefence: false),
                    .init(playerId: "p1", isDefence: true)
                ],
                "p2": [
                    .init(playerId: "p2", isDefence: false),
                    .init(playerId: "p2", isDefence: false),
                    .init(playerId: "p2", isDefence: false),
                    .init(playerId: "p2", isDefence: true)
                ]
            ])
        self.ground = .init(gameInfo: self.gameInfo)
    }
    
    override func tearDownWithError() throws {
        self.gameInfo = nil
        self.ground = nil
    }
}


extension BattleGroundTests {
    
    // 싸움 없이 이동
    func testGround_moveKnight_viaSinglePath() {
        // given
        let knight = self.player1Knights(0)
        
        // when
        let path = KnightMovePath(serialPaths: [ .init(.gae, [.start, .R1, .R2]) ])
        let result = self.ground.moveKnight([knight.id], through: path)
        
        // then
        XCTAssertEqual(result?.battles.isEmpty, true)
        XCTAssertEqual(result?.moves, [.init(knights: [knight], path: path.serialPaths.first!)])
        XCTAssertEqual(result?.finalPosition, .init([knight], at: .R2) |> \.comesFrom .~ [.R1])
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let positionR2 = movedPosition.filter { $0.current == .R2 }
        XCTAssertEqual(movedPosition.count, 1)
        XCTAssertEqual(positionR2, [.init([knight], at: .R2) |> \.comesFrom .~ [.R1]])
    }
    
    // 싸움없이 여러 경로 이동
    func testGround_moveKnight_viaSerialPath() {
        // given
        let knight = self.player1Knights(0)
        
        // when
        let path1: KnightMovePath.PathPerDice = .init(.gae, [.start, .R1, .R2])
        let path2: KnightMovePath.PathPerDice = .init(.gae, [.R2, .R3, .R4])
        let result = self.ground.moveKnight([knight.id], through: .init(serialPaths: [path1, path2]))
        
        // then
        XCTAssertEqual(result?.battles.isEmpty, true)
        XCTAssertEqual(result?.moves, [
            .init(knights: [knight], path: path1),
            .init(knights: [knight], path: path2)
        ])
        XCTAssertEqual(result?.finalPosition, .init([knight], at: .R4) |> \.comesFrom .~ [.R3])
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let positionR4 = movedPosition.filter { $0.current == .R4 }
        XCTAssertEqual(movedPosition.count, 1)
        XCTAssertEqual(positionR4, [.init([knight], at: .R4) |> \.comesFrom .~ [.R3]])
    }
}

extension BattleGroundTests {
    
    // 싸움 없이 이동 -> 마지막에 같은편 말과 합체
    func testGround_whenDestinationIsAlliance_merge() {
        // given
        let (kn1_1, kn1_2) = (self.player1Knights(0), self.player1Knights(1))
        let path = KnightMovePath(serialPaths: [ .init(.gae, [.start, .R1, .R2]) ])
        _ = ground.moveKnight([kn1_1.id], through: path)
        
        // when
        let result = ground.moveKnight([kn1_2.id], through: path)
        
        // then
        XCTAssertEqual(result?.battles.isEmpty, true)
        XCTAssertEqual(result?.moves, [ .init(knights: [kn1_2], path: path.serialPaths.first!, mergedWith: [kn1_1]) ])
        XCTAssertEqual(result?.finalPosition.knight.map { $0.id }.sorted(), [kn1_1.id, kn1_2.id].sorted())
        XCTAssertEqual(result?.finalPosition.comesFrom, [.R1])
        
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let positionR2 = movedPosition.filter { $0.current == .R2 }
        XCTAssertEqual(movedPosition.count, 1)
        XCTAssertEqual(positionR2.count, 1)
        XCTAssertEqual(
            positionR2.first?.knight.map { $0.id }.sorted(),
            [kn1_1.id, kn1_2.id].sorted()
        )
        XCTAssertEqual(positionR2.first?.comesFrom, [.R1])
    }
    
    // 싸움 없이 여러 경로 이동 -> 중간에 같은편 말과 합체
    func testGround_whenMoveSerialPathAndOneOfDestinationOccupiedByAlliance_mergeAndMove() {
        // given
        let (kn1_1, kn1_2) = (self.player1Knights(0), self.player1Knights(1))
        let path1 = KnightMovePath(serialPaths: [ .init(.doe(isBackward: false), [.start, .R1]) ])
        _ = ground.moveKnight([kn1_1.id], through: path1)
        
        // when
        let path2 = KnightMovePath(serialPaths: [ .init(.doe(isBackward: false), [.R1, .R2]) ])
        let result = ground.moveKnight(
            [kn1_2.id],
            through: .init(serialPaths: path1.serialPaths + path2.serialPaths)
        )
        
        // then
        XCTAssertEqual(result?.battles.isEmpty, true)
        
        XCTAssertEqual(result?.moves.count, 2)
        XCTAssertEqual(result?.moves.first?.knights.ids, [kn1_2.id])
        XCTAssertEqual(result?.moves.first?.path, path1.serialPaths.first!)
        XCTAssertEqual(result?.moves.first?.mergedWith.ids, [kn1_1.id])
        XCTAssertEqual(result?.moves.last?.knights.ids, [kn1_1.id, kn1_2.id].sorted())
        XCTAssertEqual(result?.moves.last?.path, path2.serialPaths.first!)
        
        XCTAssertEqual(result?.finalPosition.current, .R2)
        XCTAssertEqual(result?.finalPosition.knight.map { $0.id }.sorted() , [kn1_1.id, kn1_2.id].sorted())
        XCTAssertEqual(result?.finalPosition.comesFrom, [.R1])
        
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let positionR2 = movedPosition.filter { $0.current == .R2 }
        XCTAssertEqual(movedPosition.count, 1)
        XCTAssertEqual(positionR2.count, 1)
        XCTAssertEqual(
            positionR2.first?.knight.map { $0.id }.sorted(),
            [kn1_1.id, kn1_2.id].sorted()
        )
        XCTAssertEqual(positionR2.first?.comesFrom, [.R1])
    }
    
    // 공격말 이동중에 중간에 수비말 있으면 합체하고 이동
    func testGround_whenMoveSerialPathAndOneOfDestinationOccupiedByAllianceDefender_mergeAndMove() {
        // given
        let (kn1_a, kn1_d) = (self.player1Knights(0), self.player1Knights(3))
        let path1 = KnightMovePath(serialPaths: [ .init(.doe(isBackward: false), [.start, .R1]) ])
        _ = ground.moveKnight([kn1_d.id], through: path1)
        
        // when
        let path2 = KnightMovePath(serialPaths: [ .init(.doe(isBackward: false), [.R1, .R2]) ])
        let result = ground.moveKnight(
            [kn1_a.id],
            through: .init(serialPaths: path1.serialPaths + path2.serialPaths)
        )
        
        // then
        XCTAssertEqual(result?.battles.isEmpty, true)
        
        XCTAssertEqual(result?.moves.count, 2)
        XCTAssertEqual(result?.moves.first?.knights.ids, [kn1_a.id])
        XCTAssertEqual(result?.moves.first?.mergedWith.ids, [kn1_d.id].sorted())
        XCTAssertEqual(result?.moves.first?.path, path1.serialPaths.first!)
        XCTAssertEqual(result?.moves.last?.knights.ids, [kn1_d.id, kn1_a.id].sorted())
        XCTAssertEqual(result?.moves.last?.path, path2.serialPaths.first!)
        
        XCTAssertEqual(result?.finalPosition.current, .R2)
        XCTAssertEqual(result?.finalPosition.knight.map { $0.id }.sorted() , [kn1_d.id, kn1_a.id].sorted())
        XCTAssertEqual(result?.finalPosition.comesFrom, [.R1])
        
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let positionR2 = movedPosition.filter { $0.current == .R2 }
        XCTAssertEqual(movedPosition.count, 1)
        XCTAssertEqual(positionR2.count, 1)
        XCTAssertEqual(
            positionR2.first?.knight.map { $0.id }.sorted(),
            [kn1_d.id, kn1_a.id].sorted()
        )
        XCTAssertEqual(positionR2.first?.comesFrom, [.R1])
    }
}

extension BattleGroundTests {
    
    // 공격말 단일경로 이동 + 목적지의 상대말(1개) 죽임
    func testGround_whenKnightAttackCounterKnight_kill() {
        // given
        let (kn1, kn2) = (self.player1Knights(0), self.player2Knights(0))
        let path = KnightMovePath(serialPaths: [.init(.gae, [.start, .R1, .R2])])
        _ = ground.moveKnight([kn1.id], through: path)
        
        // when
        let result = ground.moveKnight([kn2.id], through: path)
        
        // then
        XCTAssertEqual(result?.battles, [
            .init(at: .R2, killer: [kn2], killed: [kn1], survived: [])
        ])
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let knightIdsAtR2 = movedPosition.filter { $0.current == .R2 }
            .flatMap { $0.knight }
            .map { $0.id }
        XCTAssertEqual(movedPosition.count, 1)
        XCTAssertEqual(knightIdsAtR2, [kn2.id])
    }
    
    // 공격말 단일경로 이동 + 목적지의 상대말(여러개) 죽임
    func testGround_whenKnightAttackCounterKnights_killAll() {
        // given
        let (kn1_1, kn1_2, kn2) = (
            self.player1Knights(0), self.player1Knights(1),
            self.player2Knights(0)
        )
        let path = KnightMovePath(serialPaths: [.init(.gae, [.start, .R1, .R2])])
        _ = ground.moveKnight([kn1_1.id, kn1_2.id], through: path)
        
        // when
        let result = ground.moveKnight([kn2.id], through: path)
        
        // then
        XCTAssertEqual(result?.battles, [
            .init(at: .R2, killer: [kn2], killed: [kn1_1, kn1_2], survived: [])
        ])
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let knightIdsAtR2 = movedPosition.filter { $0.current == .R2 }
            .flatMap { $0.knight }
            .map { $0.id }
        XCTAssertEqual(knightIdsAtR2, [kn2.id])
    }
    
    // 공격말 단일경로 이동 + 상대 수비말 죽임
    func testGround_whenKnightAttackCounterDefenseKnight_kill() {
        // given
        let (kn1_d, kn2_a) = (self.player1Knights(3), self.player2Knights(0))
        let path = KnightMovePath(serialPaths: [.init(.gae, [.start, .R1, .R2])])
        _ = ground.moveKnight([kn1_d.id], through: path)
        
        // when
        let result = ground.moveKnight([kn2_a.id], through: path)
        
        // then
        XCTAssertEqual(result?.battles, [
            .init(at: .R2, killer: [kn2_a], killed: [kn1_d], survived: [])
        ])
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let knightIdsAtR2 = movedPosition.filter { $0.current == .R2 }
            .flatMap { $0.knight }
            .map { $0.id }
        XCTAssertEqual(movedPosition.count, 1)
        XCTAssertEqual(knightIdsAtR2, [kn2_a.id])
    }
    
    // 공격말 단일경로 이동 + 상대 수비말+공격말 조합 공격시 수비말만 죽음
    func testGround_whenKnightAttackCounterKnightsWithDefender_killOnlyDefender() {
        // given
        let (kn1_a, kn1_d, kn2) = (
            self.player1Knights(0), self.player1Knights(3),
            self.player2Knights(0)
        )
        let path = KnightMovePath(serialPaths: [.init(.gae, [.start, .R1, .R2])])
        _ = ground.moveKnight([kn1_a.id, kn1_d.id], through: path)
        
        // when
        let result = ground.moveKnight([kn2.id], through: path)
        
        // then
        XCTAssertEqual(result?.battles, [
            .init(at: .R2, killer: [kn2], killed: [kn1_d], survived: [kn1_a])
        ])
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let knightIdsAtR2 = movedPosition.filter { $0.current == .R2 }
            .flatMap { $0.knight }
            .map { $0.id }
            .sorted()
        XCTAssertEqual(movedPosition.count, 2)
        XCTAssertEqual(knightIdsAtR2, [kn2.id, kn1_a.id].sorted())
    }
    
    // 공격말 이동중 중간 목적지에 상대말 있으면 다 잡아먹고 이동
    func testGround_whenKnightMoves_killAllCounterKnightsOnPathDestinations() {
        // given
        let (kn1_1, kn1_2, kn1_3, kn2) = (
            self.player1Knights(0), self.player1Knights(1), self.player1Knights(2),
            self.player2Knights(0)
        )
        let path1 = KnightMovePath(serialPaths: [.init(.doe(isBackward: false), [.start, .R1])])
        let path2 = KnightMovePath(serialPaths: [.init(.doe(isBackward: false), [.R1, .R2])])
        let path3 = KnightMovePath(serialPaths: [.init(.doe(isBackward: false), [.R2, .R3])])
        _ = ground.moveKnight([kn1_1.id], through: path1)
        _ = ground.moveKnight([kn1_2.id], through: path2)
        _ = ground.moveKnight([kn1_3.id], through: path3)
        
        // when
        let result = ground.moveKnight(
            [kn2.id], through: .init(serialPaths: path1.serialPaths + path2.serialPaths + path3.serialPaths))
        
        // then
        XCTAssertEqual(result?.battles, [
            .init(at: .R1, killer: [kn2], killed: [kn1_1], survived: []),
            .init(at: .R2, killer: [kn2], killed: [kn1_2], survived: []),
            .init(at: .R3, killer: [kn2], killed: [kn1_3], survived: []),
        ])
        let movedPosition = self.ground.knightPositions.filter { $0.current != .start }
        let knightIdsAtR3 = movedPosition.filter { $0.current == .R3 }
            .flatMap { $0.knight }
            .map { $0.id }
            .sorted()
        XCTAssertEqual(movedPosition.count, 1)
        XCTAssertEqual(knightIdsAtR3, [kn2.id].sorted())
    }
}
