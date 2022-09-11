//
//  KnightPathSuggestServiceImpleTests_attack.swift
//  DomainTests
//
//  Created by sudo.park on 2022/09/07.
//

import XCTest

import AsyncAlgorithms
@testable import Domain

class KnightPathSuggestServiceImpleTests_attack: KnightPathSuggestServiceImpleTests {
    
    var attacker: Knights {
        return [.init(playerId: "some", isDefence: false)]
    }
}


extension KnightPathSuggestServiceImpleTests_attack {
    
    func testService_suggestShortCutFromShortCutPositions() async {
        // given
        
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
    
    func testService_suggestShortPath_viaCTR_INT() async {
        // given
        
        // when
        let dices = Array(repeating: BinaryDice.doe(isBackward: false), count: 13)
        let movePaths = await self.knightSerailMovePaths(self.attacker, for: dices)
        
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
        
        // when
        let dices: [BinaryDice] = [
            .yut, .gae, .gul, .doe(isBackward: false), .yut, .gae, .gul
        ]
        let movePaths = await self.knightSerailMovePaths(self.attacker, for: dices)
        
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
        
        // when
        let dices: [BinaryDice] = [
            .mo, .yut, .yut, .mo
        ]
        let movePaths = await self.knightSerailMovePaths(self.attacker, for: dices)
        
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
        
        // when
        let dices: [BinaryDice] = [
            .yut, .yut, .yut, .yut, .yut, .doe(isBackward: false)
        ]
        let movePaths = await self.knightSerailMovePaths(self.attacker, for: dices)
        
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

extension KnightPathSuggestServiceImpleTests_attack {

    func testService_whenBackdoeFromStart_noSuggestingPath() async {
        // given
        
        // when
        let dices: [BinaryDice] = [.doe(isBackward: true)]
        let paths = await self.knightSerailMovePaths(self.attacker, for: dices)
        
        // then
        let visitNodes = paths.map { $0.serialPaths }
        XCTAssertEqual(visitNodes, [
            [[.start]]
        ])
    }
    
    func testService_whenINTPositionKnightIsComeFromDL2_suggestDL2() async {
        // given
        
        // when
        var position = KnightPosition(self.attacker, at: .INT)
        position.comesFrom = [.DL2]
        let paths = await service.suggestPath(at: position, with: [.doe(isBackward: true)])
        
        // then
        let nodes = paths.map { $0.serialPaths }
        XCTAssertEqual(nodes, [
            [ [.INT, .DL2] ]
        ])
    }
    
    func testService_whenINTPositionKnightIsComeFromDR2_suggestDR2() async {
        // given
        
        // when
        var position = KnightPosition(self.attacker, at: .INT)
        position.comesFrom = [.DR2]
        let paths = await service.suggestPath(at: position, with: [.doe(isBackward: true)])
        
        // then
        let nodes = paths.map { $0.serialPaths }
        XCTAssertEqual(nodes, [
            [ [.INT, .DR2] ]
        ])
    }
    
    func testService_whenINTPositionKnightsComeFromDL2AndDR2_suggestDL2_DR2() async {
        // given
        
        // when
        var position = KnightPosition(self.attacker, at: .INT)
        position.comesFrom = [.DL2, .DR2]
        let paths = await service.suggestPath(at: position, with: [.doe(isBackward: true)])
        
        // then
        let pathToDL2 = KnightMovePath(serialPaths: [ [.INT, .DL2] ])
        let pathToDR2 = KnightMovePath(serialPaths: [ [.INT, .DR2] ])
        XCTAssertEqual(paths.count, 2)
        XCTAssertEqual(paths.contains(pathToDL2), true)
        XCTAssertEqual(paths.contains(pathToDR2), true)
    }
    
    func testService_whenCBLPositionKnightIsComeFromDL4_suggestDL4() async {
        // given
        
        // when
        var position = KnightPosition(self.attacker, at: .CBL)
        position.comesFrom = [.DL4]
        let paths = await service.suggestPath(at: position, with: [.doe(isBackward: true)])
        
        // then
        let nodes = paths.map { $0.serialPaths }
        XCTAssertEqual(nodes, [
            [ [.CBL, .DL4] ]
        ])
    }
    
    func testService_whenCBLPositionKnightIsComeFromL4_suggestL4() async {
        // given
        
        // when
        var position = KnightPosition(self.attacker, at: .CBL)
        position.comesFrom = [.L4]
        let paths = await service.suggestPath(at: position, with: [.doe(isBackward: true)])
        
        // then
        let nodes = paths.map { $0.serialPaths }
        XCTAssertEqual(nodes, [
            [ [.CBL, .L4] ]
        ])
    }
    
    func testService_whenCBLPositionKnightsComeFromDL4AndL4_suggestDL4_L4() async {
        // given
        
        // when
        var position = KnightPosition(self.attacker, at: .CBL)
        position.comesFrom = [.DL4, .L4]
        let paths = await service.suggestPath(at: position, with: [.doe(isBackward: true)])
        
        // then
        let pathToDL4 = KnightMovePath(serialPaths: [ [.CBL, .DL4] ])
        let pathToL4 = KnightMovePath(serialPaths: [ [.CBL, .L4] ])
        XCTAssertEqual(paths.count, 2)
        XCTAssertEqual(paths.contains(pathToDL4), true)
        XCTAssertEqual(paths.contains(pathToL4), true)
    }
    
    func testService_suggestPath_backDoeviaR1CBR() async {
        // given
        
        // when
        var position = KnightPosition(self.attacker, at: .start)
        var paths = await service.suggestPath(at: position, with: [.doe(isBackward: false)])
        
        position = KnightPosition(self.attacker, at: .R1)
        position.comesFrom = [.start]
        paths += await service.suggestPath(at: position, with: [.doe(isBackward: true)])
        
        position = KnightPosition(self.attacker, at: .CBR)
        position.comesFrom = [.R1]
        paths += await service.suggestPath(at: position, with: [.gae])
        
        // then
        let visitNodes = paths.map { $0.serialPaths }
        XCTAssertEqual(visitNodes, [
            [ [.start, .R1] ],
            [ [.R1, .CBR] ],
            [ [.CBR, .out] ]
        ])
    }
    
    func testService_suggestPath_backDoeviaR1CBRAndBackDoe_moveToR1() async {
        // given
        
        // when
        var position = KnightPosition(self.attacker, at: .start)
        var paths = await service.suggestPath(at: position, with: [.doe(isBackward: false)])
        
        position = KnightPosition(self.attacker, at: .R1)
        position.comesFrom = [.start]
        paths += await service.suggestPath(at: position, with: [.doe(isBackward: true)])
        
        position = KnightPosition(self.attacker, at: .CBR)
        position.comesFrom = [.R1]
        paths += await service.suggestPath(at: position, with: [.doe(isBackward: true)])
        
        // then
        let visitNodes = paths.map { $0.serialPaths }
        XCTAssertEqual(visitNodes, [
            [ [.start, .R1] ],
            [ [.R1, .CBR] ],
            [ [.CBR, .R1] ]
        ])
    }
    
    func testService_suggesKnighttPath_withBackwardDoe() async {
        // given
        
        // when
        let dices: [BinaryDice] = [
            .mo, .doe(isBackward: true)
        ]
        var position = KnightPosition(self.attacker, at: .T1)
        position.comesFrom = [.CTR]
        let paths = await service.suggestPath(at: position, with: dices)
        
        // then
        let pathToMoveAndBack = KnightMovePath(serialPaths: [
            [.T1, .T2, .T3, .T4, .CTL, .L1], [.L1, .CTL]
        ])
        let pathBackAndMove = KnightMovePath(serialPaths: [
            [.T1, .CTR], [.CTR, .DL1, .DL2, .INT, .DL3, .DL4]
        ])
        XCTAssertEqual(paths.count, 2)
        XCTAssertEqual(paths.contains(pathToMoveAndBack), true)
        XCTAssertEqual(paths.contains(pathBackAndMove), true)
    }
    
    func testService_suggestKnightsPath_wthBackward() async {
        // given
        
        // when
        let dices: [BinaryDice] = [
            .gae, .doe(isBackward: true)
        ]
        var position = KnightPosition(self.attacker, at: .INT)
        position.comesFrom = [.DL2, .DR2]
        let paths = await service.suggestPath(at: position, with: dices)
        
        // then
        let pathMoveAndBack = KnightMovePath(serialPaths: [
            [.INT, .DR3, .DR4], [.DR4, .DR3]
        ])
        let pathBackToDLAndMove = KnightMovePath(serialPaths: [
            [.INT, .DL2], [.DL2, .INT, .DL3]
        ])
        let pathBackToDRAndMove = KnightMovePath(serialPaths: [
            [.INT, .DR2], [.DR2, .INT, .DR3]
        ])
        XCTAssertEqual(paths.count, 3)
        XCTAssertEqual(paths.contains(pathMoveAndBack), true)
        XCTAssertEqual(paths.contains(pathBackToDLAndMove), true)
        XCTAssertEqual(paths.contains(pathBackToDRAndMove), true)
    }
}
