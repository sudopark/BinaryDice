//
//  KnightPathSuggestServiceImpleTests_defence.swift
//  DomainTests
//
//  Created by sudo.park on 2022/09/10.
//

import XCTest

@testable import Domain


class KnightPathSuggestServiceImpleTests_defence: KnightPathSuggestServiceImpleTests {
    
    var defender: Knights {
        return Knights(knights: [.init(playerId: "some", isDefence: true)])
    }
}


extension KnightPathSuggestServiceImpleTests_defence {
    
    
    // 한 지점에서 복수 방향으로 경로 추천
        // 시작점에서 B4, DR4
        // CBL에서 DL4, L4
        // INT에서 DL2, DR2
    func testService_whenBranchPoint_suggestMultiplePath() async {
        // given
        
        // when
        var position = KnightPosition(self.defender, at: .start)
        let pathsFromStart = await service.suggestPath(at: position, with: [.gae])
        
        position = KnightPosition(self.defender, at: .CBL)
        let pathsFromCBL = await service.suggestPath(at: position, with: [.gae])
        
        position = KnightPosition(self.defender, at: .INT)
        let pathsFromINT = await service.suggestPath(at: position, with: [.gae])
        
        // then
        XCTAssertEqual(pathsFromStart.count, 2)
        XCTAssertEqual(pathsFromStart.hasPath([ [.start, .DR4, .DR3] ]), true)
        XCTAssertEqual(pathsFromStart.hasPath([ [.start, .B4, .B3] ]), true)
        
        XCTAssertEqual(pathsFromCBL.count, 2)
        XCTAssertEqual(pathsFromCBL.hasPath([ [.CBL, .DL4, .DL3] ]), true)
        XCTAssertEqual(pathsFromCBL.hasPath([ [.CBL, .L4, .L3] ]), true)
        
        XCTAssertEqual(pathsFromINT.count, 2)
        XCTAssertEqual(pathsFromINT.hasPath([ [.INT, .DL2, .DL1] ]), true)
        XCTAssertEqual(pathsFromINT.hasPath([ [.INT, .DR2, .DR1] ]), true)
    }
    
    // 분기지점에서 복수 dice 조합(순열) 추천
    func testService_whenDoubleDicesAndOneOfDestinationIsBranchPoint_suggesMultiplePathsWithBranched() async {
        
        // given
        
        // when
        let position = KnightPosition(self.defender, at: .start)
        let paths = await service.suggestPath(at: position, with: [.mo, .gae])
        
        // then
        XCTAssertEqual(paths.count, 5)
        XCTAssertEqual(paths.hasPath([
            [.start, .B4, .B3, .B2, .B1, .CBL], [.CBL, .L4, .L3]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.start, .B4, .B3], [.B3, .B2, .B1, .CBL, .L4, .L3]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.start, .B4, .B3, .B2, .B1, .CBL], [.CBL, .DL4, .DL3]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.start, .DR4, .DR3, .INT, .DR2, .DR1], [.DR1, .CTL, .T4]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.start, .DR4, .DR3], [.DR3, .INT, .DR2, .DR1, .CTL, .T4]
        ]), true)
    }
    
    // 도착지가 분기지점이 아닌경우에는 한가지 경로만 추천
        // B1 -> CBL -> L4
        // DR3 -> INT -> DR2
    func testService_whenPointIsNotBranchPoint_suggestOnePath() async {
        // given
        
        // when
        var position = KnightPosition(self.defender, at: .B1)
        let pathsFromB1 = await service.suggestPath(at: position, with: [.gae])
        
        position = .init(self.defender, at: .DR3)
        let pathsFromCR3 = await service.suggestPath(at: position, with: [.gae])
        
        // then
        XCTAssertEqual(pathsFromB1.count, 1)
        XCTAssertEqual(pathsFromB1.hasPath([ [.B1, .CBL, .L4] ]), true)
        XCTAssertEqual(pathsFromCR3.count, 1)
        XCTAssertEqual(pathsFromCR3.hasPath([ [.DR3, .INT, .DR2] ]), true)
    }
    
    // 방어경로 최단경로 추천: START -> INT -> CTR -> OUT
    func testService_suggestPath_via_INT_CTR() async {
        // given
        var paths: [KnightMovePath] = []
        
        // when
        var position = KnightPosition(self.defender, at: .start)
        paths += await service.suggestPath(at: position, with: [.gul])
        
        position = KnightPosition(self.defender, at: .INT)
        paths += await service.suggestPath(at: position, with: [.gul])
        
        position = KnightPosition(self.defender, at: .CTR)
        paths += await service.suggestPath(at: position, with: [.mo])
        
        position = KnightPosition(self.defender, at: .CBR)
        paths += await service.suggestPath(at: position, with: [.doe(isBackward: false)])
        
        // then
        XCTAssertEqual(paths.hasPath([
            [.start, .DR4, .DR3, .INT]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.INT, .DL2, .DL1, .CTR]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.CTR, .R4, .R3, .R2, .R1, .CBR]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.CBR, .out]
        ]), true)
    }
    
    // 방어경로 단축경로1 추천: START -> CTL -> CTR -> OUT
    func testService_suggestPath_via_CTL_CTR() async {
        // given
        var paths: [KnightMovePath] = []
        
        // when
        var position = KnightPosition(self.defender, at: .start)
        paths += await service.suggestPath(at: position, with: [.mo])

        position = KnightPosition(self.defender, at: .DR1)
        paths += await service.suggestPath(at: position, with: [.mo])
        
        position = KnightPosition(self.defender, at: .T1)
        paths += await service.suggestPath(at: position, with: [.mo])
        
        position = KnightPosition(self.defender, at: .R1)
        paths += await service.suggestPath(at: position, with: [.gae])
        
        // then
        XCTAssertEqual(paths.hasPath([
            [.start, .DR4, .DR3, .INT, .DR2, .DR1]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.DR1, .CTL, .T4, .T3, .T2, .T1]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.T1, .CTR, .R4, .R3, .R2, .R1]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.R1, .CBR, .out]
        ]), true)
    }
    
    func testService_suggestPath_via_CBL_CTR() async {
        // given
        var paths: [KnightMovePath] = []
        
        // when
        var position = KnightPosition(self.defender, at: .start)
        paths += await service.suggestPath(at: position, with: [.mo])

        position = KnightPosition(self.defender, at: .CBL)
        paths += await service.suggestPath(at: position, with: [.mo])
        
        position = KnightPosition(self.defender, at: .DL1)
        paths += await service.suggestPath(at: position, with: [.mo])
        
        position = KnightPosition(self.defender, at: .R1)
        paths += await service.suggestPath(at: position, with: [.gae])
        
        // then
        XCTAssertEqual(paths.hasPath([
            [.start, .B4, .B3, .B2, .B1, .CBL]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.CBL, .DL4, .DL3, .INT, .DL2, .DL1]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.DL1, .CTR, .R4, .R3, .R2, .R1]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.R1, .CBR, .out]
        ]), true)
    }
    
    // 방어경로 외곽 경로 추천: START -> CBL -> CTL -> CTR -> OUT
    func testService_suggestPath_via_CBL_CTL_CTR() async {
        // given
        var paths: [KnightMovePath] = []
        
        // when
        var position = KnightPosition(self.defender, at: .start)
        paths += await service.suggestPath(at: position, with: [.yut])
        
        position = KnightPosition(self.defender, at: .B1)
        paths += await service.suggestPath(at: position, with: [.yut])
        
        position = KnightPosition(self.defender, at: .L2)
        paths += await service.suggestPath(at: position, with: [.yut])
        
        position = KnightPosition(self.defender, at: .T3)
        paths += await service.suggestPath(at: position, with: [.yut])
        
        position = KnightPosition(self.defender, at: .R4)
        paths += await service.suggestPath(at: position, with: [.yut])
        
        position = KnightPosition(self.defender, at: .CBR)
        paths += await service.suggestPath(at: position, with: [.doe(isBackward: false)])
        
        // then
        XCTAssertEqual(paths.hasPath([
            [.start, .B4, .B3, .B2, .B1]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.B1, .CBL, .L4, .L3, .L2]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.L2, .L1, .CTL, .T4, .T3]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.T3, .T2, .T1, .CTR, .R4]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.R4, .R3, .R2, .R1, .CBR]
        ]), true)
        XCTAssertEqual(paths.hasPath([
            [.CBR, .out]
        ]), true)
    }
}

private extension Array where Element == KnightMovePath {
    
    func hasPath(_ serialpath: [KnightMovePath.PathPerDice]) -> Bool {
        let path = KnightMovePath(serialPaths: serialpath)
        return self.contains(path)
    }
}
