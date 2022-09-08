//
//  KnightPathSuggestService.swift
//  Domain
//
//  Created by sudo.park on 2022/09/06.
//

import Foundation
import Algorithms

public struct KnightMovePath: Equatable {
    
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
        
        typealias PathPerDice = KnightMovePath.PathPerDice
        let asSerialPaths: ([PathPerDice], BinaryDice) -> [PathPerDice] = { acc, dice in
            let startNode = acc.last?.last ?? position.current
            switch dice {
            case .doe(isBackward: true):
                let next = findAttackerBackwardPath(startNode)
                return acc + [next]
                
            default:
                let step = abs(dice.numberOfMove)
                let next = findAttackerNextNode(startNode, step: step)
                return acc + [next]
            }
        }
        
        let paths = serializedDices.reduce([], asSerialPaths)
        return .init(serialPaths: paths)
    }
    
    private func findAttackerNextNode(_ from: Node, step: Int) -> KnightMovePath.PathPerDice {
        var remain = step
        var nodes = [from]
        while remain > 0 {
            
            let (previous, current, isFirst) = (nodes[safe: nodes.count-2], nodes.last!, remain == step)
            
            guard let next = self.chooseAttackNextNode(previous, current, isFirst)
            else {
                return nodes
            }
            nodes.append(next)
            remain -= 1
        }
        return nodes
    }
    
    private func chooseAttackNextNode(_ previous: Node?, _ current: Node, _ isFirstStep: Bool) -> Node? {
        switch current {
        case .start: return .R1
        case .R1: return .R2
        case .R2: return .R3
        case .R3: return .R4
        case .R4: return .CTR
        case .CTR where isFirstStep: return .DL1
        case .CTR: return .T1
        case .T1: return .T2
        case .T2: return .T3
        case .T3: return .T4
        case .T4: return .CTL
        case .CTL where isFirstStep: return .DR1
        case .CTL: return .L1
        case .L1: return .L2
        case .L2: return .L3
        case .L3: return .L4
        case .L4: return .CBL
        case .CBL: return .B1
        case .B1: return .B2
        case .B2: return .B3
        case .B3: return .B4
        case .B4: return .CBR
        case .DL1: return .DL2
        case .DL2: return .INT
        case .INT where isFirstStep: return .DR3
        case .INT where previous == .DL2: return .DL3
        case .INT: return .DR3
        case .DL3: return .DL4
        case .DL4: return .CBL
        case .DR1: return .DR2
        case .DR2: return .INT
        case .DR3: return .DR4
        case .DR4: return .CBR
        case .CBR: return .out
        case .out: return nil
        }
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
