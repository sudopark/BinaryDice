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
    
    func testService_suggestShortPath_viaCTR_INT() async {
        // given
        let service = KnightPathSuggestServiceImple()
        
        // when
        let movePaths = await (1...13).async.reduce(into: [KnightMovePath]()) { acc, _ in
            let currentNode = acc.last?.destination ?? .start
            let position = KnightPosition(self.attacker, at: currentNode)
            let nextPath = await service.suggestPath(at: position, with: [.doe(isBackward: false)])
            acc += nextPath
        }
        let visitNodes = movePaths.map { $0.serialPaths }
        
        // then
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
}
