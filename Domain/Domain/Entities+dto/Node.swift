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

public enum Node: String, Sendable {
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
