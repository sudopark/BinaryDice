//
//  KnightPathSuggestService.swift
//  Domain
//
//  Created by sudo.park on 2022/09/06.
//

import Foundation
import Algorithms

public struct KnightMovePath {
    
    public typealias PathPerDice = [Node]
    
    public let serialPaths: [PathPerDice]
    
    public var destination: Node? {
        return self.serialPaths.flatMap { $0 }.last
    }
}

public protocol KnightPathSuggestService {
    
    func suggestPath(
        at position: KnightPosition,
        with dices: [BinaryDice]
    ) async -> [KnightMovePath]
}


public struct KnightPathSuggestServiceImple: KnightPathSuggestService {
    
    private let attackerPaths: [Node: Node.NextNodes] = Node.attackLinkedPath
    private let defenderPaths: [Node: Node.NextNodes] = Node.defenceLinkedPath
    
    public init() { }
    
    public func suggestPath(
        at position: KnightPosition,
        with dices: [BinaryDice]
    ) async -> [KnightMovePath] {
        return await withCheckedContinuation { continuation in
            let path = position.knight.isDefence
                ? self.suggestPathsForDefender(at: position, with: dices)
                : self.suggestPathsForAttacker(at: position, with: dices)
            continuation.resume(returning: path)
        }
    }
}


// MARK: - suggest for attacker

extension KnightPathSuggestServiceImple {
    
    private func suggestPathsForAttacker(
        at position: KnightPosition,
        with dices: [BinaryDice]
    ) -> [KnightMovePath] {
        
        guard dices.isEmpty == false else { return [] }
        
        // of count range 집어넣으면 총 던진 윷 중에서 1개 윷 ~ 전체 윷 순열로 갈수있는 모든 경로가 표시됨, 유저가 지점 선택시에 선택된 KnightMovePath로 쉽게 선택된 값을 찾을 수 있지만 연산량 + 결과값이 늘어남
        // of count range 안넣으면 전체 윷 순열로 갈수있는 지점들이 표시됨 -> 중간에 들려야하는 노드들은 KnightMovePath.PathPerDice 들로 표시 가능하지만 무엇이 선택되었는지 판단하기 어려움? -> UI 단 구현시에 별도 처리 가능
        // -> 일단은 of count range 없이 가는 방향으로
        let possibleDiceSelections = dices.permutations()
        
        return possibleDiceSelections
            .map { self.findPathForAttacker(at: position, with: $0) }
    }
    
    private func findPathForAttacker(
        at position: KnightPosition,
        with serializedDices: [BinaryDice]
    ) -> KnightMovePath {
        
        let asOneStepPath: (BinaryDice) -> KnightMovePath.PathPerDice = { dice in
            switch dice {
            case .doe(isBackward: true):
                return self.findAttackerBackwardPath(position.current)
                
            default:
                let step = abs(dice.numberOfMove)
                return self.findAttackerNextNode(position.current, step: step)
            }
        }
        
        let paths = serializedDices.map(asOneStepPath)
        return .init(serialPaths: paths)
    }
    
    private func findAttackerNextNode(_ from: Node, step: Int) -> KnightMovePath.PathPerDice {
        var remain = step
        var nodes = [from]
        while remain > 0 {
            let current = nodes.last!
            
            guard current != .out, let nexts = self.attackerPaths[from]
            else { return nodes }
            
            if let shortCut = nexts.nextShortCutNode, remain == step {
                nodes.append(shortCut)
            } else {
                nodes.append(nexts.nextNode)
            }
            remain -= 1
        }
        return nodes
    }
    
    private func findAttackerBackwardPath(_ from: Node) -> KnightMovePath.PathPerDice {
        // TODO
        return [from]
    }
}


// MARK: - Suggest for defender

extension KnightPathSuggestServiceImple {
    
    private func suggestPathsForDefender(
        at position: KnightPosition,
        with dices: [BinaryDice]
    ) -> [KnightMovePath] {
        // TODO
        return []
    }
}
