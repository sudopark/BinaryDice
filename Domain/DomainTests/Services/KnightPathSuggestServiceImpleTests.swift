//
//  KnightPathSuggestServiceImpleTests.swift
//  DomainTests
//
//  Created by sudo.park on 2022/09/11.
//

import XCTest

@testable import Domain


class KnightPathSuggestServiceImpleTests: XCTestCase {
    
    var service: KnightPathSuggestServiceImple!
    
    override func setUpWithError() throws {
        self.service = .init()
    }
    
    override func tearDownWithError() throws {
        self.service = nil
    }
    
    func knightSerailMovePaths(
        _ knights: Knights,
        for dices: [BinaryDice]
    ) async -> [KnightMovePath] {
        return await dices.async.reduce(into: [KnightMovePath]()) { acc, dice in
            let currentNode = acc.last?.destination ?? .start
            let position = KnightPosition(knights, at: currentNode)
            let nextPath = await service.suggestPath(at: position, with: [dice])
            acc += nextPath
        }
    }
}
