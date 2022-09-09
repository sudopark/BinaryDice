//
//  Node.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public typealias NodeId = String

/**
 node map
 (CTL) ---- ( T4) ---- (T3) ---- (T2) ---- ( T1) ---- (CTR)
  |
 
 (L1)        (DR1)                                 (DL1)       (R4)
  |
 
 (:2)                 (DR2)                      (DL2)          (R3)
  |
 
 (L3)                              (INT)                             (R2)
  |
            (DL3)               (DR3)
 (L4)                                                                   (R1)
  |         (DL4)                                       (DR4)
 
(CBL)        (B1)        (B2)      (B3)        (B4)        (CBR)
 */

public enum Node: String {
    case start
    case CBR, R1, R2, R3, R4
    case CTR
    case T1, T2, T3, T4
    case CTL
    case L1, L2, L3, L4
    case CBL
    case B1, B2, B3, B4
    case INT
    case DL1, DL2, DL3, DL4
    case DR1, DR2, DR3, DR4
    case out
}


// MARK: - Node map

extension Node {
    
    struct NextNodes {
        
        let nextNode: Node
        let nextShortCutNode: Node?
        
        init(_ nextNode: Node, shortCut: Node? = nil) {
            self.nextNode = nextNode
            self.nextShortCutNode = shortCut
        }
    }
    
    static var defenceLinkedPath: [Node: NextNodes] {
        [
            .start: .init(.B4, shortCut: .DR4),
            .B4: .init(.B3),
            .B3: .init(.B2),
            .B2: .init(.B1),
            .B1: .init(.CBL),
            .CBL: .init(.L4, shortCut: .DL4),
            .L4: .init(.L3),
            .L3: .init(.L2),
            .L2: .init(.L1),
            .L1: .init(.CTL),
            .CTL: .init(.T4),
            .T4: .init(.T3),
            .T3: .init(.T2),
            .T2: .init(.T1),
            .T1: .init(.CTR),
            .CTR: .init(.R4),
            .R4: .init(.R3),
            .R3: .init(.R2),
            .R2: .init(.R1),
            .R1: .init(.CBR),
            .DL4: .init(.DL3),
            .DL3: .init(.INT),
            .INT: .init(.DL2, shortCut: .DR2),
            .DL2: .init(.DL1),
            .DL1: .init(.CTR),
            .DR4: .init(.DR3),
            .DR3: .init(.INT),
            .DR2: .init(.DR1),
            .DR1: .init(.CTL),
            .CBR: .init(.out)
        ]
    }
    
    func isDefenderShortPath(from: Node, to: Node) -> Bool {
        switch (from, to) {
        case (.INT, .DL2), (.CBL, .DL4): return true
        default: return false
        }
    }
}
