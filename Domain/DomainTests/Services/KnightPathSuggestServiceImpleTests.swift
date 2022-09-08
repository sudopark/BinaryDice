//
//  KnightPathSuggestServiceImpleTests.swift
//  DomainTests
//
//  Created by sudo.park on 2022/09/07.
//

import XCTest

import AsyncAlgorithms
@testable import Domain

class KnightPathSuggestServiceImpleTests: XCTestCase {
    
    var attacker: Knights {
        return Knights(knights: [.init(playerId: "some", isDefence: false)])
    }
}


extension KnightPathSuggestServiceImpleTests {
    
    func testService_suggestShortCutFromShortCutPositions() async {
        // given
        let service = KnightPathSuggestServiceImple()
        
        // when
        let pointCTR = KnightPosition(self.attacker, at: .CTR)
        let pathFromCTR = await service.suggestPath(at: pointCTR, with: [.doe(isBackward: false)])
        
        let pointINT = KnightPosition(self.attacker, at: .INT)
        let pathFromINT = await service.suggestPath(at: pointINT, with: [.doe(isBackward: false)])
        
        let pointCTL = KnightPosition(self.attacker, at: .CTL)
        let pathFromCTL = await service.suggestPath(at: pointCTL, with: [.doe(isBackward: false)])
        
        // then
        XCTAssertEqual(pathFromCTR, [.init(serialPaths: [ [.CTR, .DL1] ])])
        XCTAssertEqual(pathFromCTL, [.init(serialPaths: [ [.CTL, .DR1] ])])
        XCTAssertEqual(pathFromINT, [.init(serialPaths: [ [.INT, .DR3] ])])
    }
    
    func testService_whenDestinationIsNotShortPathPoint_suggestNotShortPath() async {
        // given
        let service = KnightPathSuggestServiceImple()
        
        // when
        let pointR4 = KnightPosition(self.attacker, at: .R4)
        let pathFromR4 = await service.suggestPath(at: pointR4, with: [.gae])
        
        let pointDL2 = KnightPosition(self.attacker, at: .DL2)
        let pathFromDL2 = await service.suggestPath(at: pointDL2, with: [.gae])
        
        let pointT4 = KnightPosition(self.attacker, at: .T4)
        let pathFromT4 = await service.suggestPath(at: pointT4, with: [.gae])
        
        // then
        XCTAssertEqual(pathFromR4, [.init(serialPaths: [ [.R4, .CTR, .T1] ])])
        XCTAssertEqual(pathFromDL2, [.init(serialPaths: [ [.DL2, .INT, .DL3] ])])
        XCTAssertEqual(pathFromT4, [.init(serialPaths: [ [.T4, .CTL, .L1] ])])
    }
    
    func testService_whenTwoDices_suggestPathsWithPermutation() async {
        // given
        let service = KnightPathSuggestServiceImple()
        
        // when
        let pointStart = KnightPosition(self.attacker, at: .start)
        let paths = await service.suggestPath(at: pointStart, with: [.gae, .gul])
        
        // then
        let pathGaeGul = KnightMovePath(serialPaths: [ [.start, .R1, .R2], [.R2, .R3, .R4, .CTR] ])
        let pathGulGae = KnightMovePath(serialPaths: [ [.start, .R1, .R2, .R3], [.R3, .R4, .CTR] ])
        XCTAssertEqual(paths.count, 2)
        XCTAssertEqual(paths.contains(pathGaeGul), true)
        XCTAssertEqual(paths.contains(pathGulGae), true)
    }
    
    private func knightSerailAttackMovePaths(
        _ service: KnightPathSuggestServiceImple,
        for dices: [BinaryDice]
    ) async -> [KnightMovePath] {
        return await dices.async.reduce(into: [KnightMovePath]()) { acc, dice in
            let currentNode = acc.last?.destination ?? .start
            let position = KnightPosition(self.attacker, at: currentNode)
            let nextPath = await service.suggestPath(at: position, with: [dice])
            acc += nextPath
        }
    }
    
    func testService_suggestShortPath_viaCTR_INT() async {
        // given
        let service = KnightPathSuggestServiceImple()
        
        // when
        let dices = Array(repeating: BinaryDice.doe(isBackward: false), count: 13)
        let movePaths = await self.knightSerailAttackMovePaths(service, for: dices)
        
        // then
        let visitNodes = movePaths.map { $0.serialPaths }
        XCTAssertEqual(visitNodes, [
            [ [.start, .R1] ],
            [ [.R1, .R2] ],
            [ [.R2, .R3] ],
            [ [.R3, .R4] ],
            [ [.R4, .CTR] ],
            [ [.CTR, .DL1] ],
            [ [.DL1, .DL2] ],
            [ [.DL2, .INT] ],
            [ [.INT, .DR3] ],
            [ [.DR3, .DR4] ],
            [ [.DR4, .CBR] ],
            [ [.CBR, .out] ],
            [ [.out] ]
        ])
    }
    
    func testService_suggestShortPath_viaCTL() async {
        // given
        let service = KnightPathSuggestServiceImple()
        
        // when
        let dices: [BinaryDice] = [
            .yut, .gae, .gul, .doe(isBackward: false), .yut, .gae, .gul
        ]
        let movePaths = await self.knightSerailAttackMovePaths(service, for: dices)
        
        // then
        let visitNodes = movePaths.map { $0.serialPaths }
        XCTAssertEqual(visitNodes, [
            [ [.start, .R1, .R2, .R3, .R4] ],
            [ [.R4, .CTR, .T1] ],
            [ [.T1, .T2, .T3, .T4] ],
            [ [.T4, .CTL] ],
            [ [.CTL, .DR1, .DR2, .INT, .DR3] ],
            [ [.DR3, .DR4, .CBR] ],
            [ [.CBR, .out] ]
        ])
    }
    
    func testService_suggestShortPath_viaCTR_CBL() async {
        // given
        let service = KnightPathSuggestServiceImple()
        
        // when
        let dices: [BinaryDice] = [
            .mo, .yut, .yut, .mo
        ]
        let movePaths = await self.knightSerailAttackMovePaths(service, for: dices)
        
        // then
        let visitNodes = movePaths.map { $0.serialPaths }
        XCTAssertEqual(visitNodes, [
            [ [.start, .R1, .R2, .R3, .R4, .CTR] ],
            [ [.CTR, .DL1, .DL2, .INT, .DL3] ],
            [ [.DL3, .DL4, .CBL, .B1, .B2] ],
            [ [.B2, .B3, .B4, .CBR, .out] ]
        ])
    }
    
    func testService_suggestAllRoundPath() async {
        // given
        let service = KnightPathSuggestServiceImple()
        
        // when
        let dices: [BinaryDice] = [
            .yut, .yut, .yut, .yut, .yut, .doe(isBackward: false)
        ]
        let movePaths = await self.knightSerailAttackMovePaths(service, for: dices)
        
        // then
        let visitNodes = movePaths.map { $0.serialPaths }
        XCTAssertEqual(visitNodes, [
            [ [.start, .R1, .R2, .R3, .R4] ],
            [ [.R4, .CTR, .T1, .T2, .T3] ],
            [ [.T3, .T4, .CTL, .L1, .L2] ],
            [ [.L2, .L3, .L4, .CBL, .B1] ],
            [ [.B1, .B2, .B3, .B4, .CBR] ],
            [ [.CBR, .out] ]
        ])
    }
}
