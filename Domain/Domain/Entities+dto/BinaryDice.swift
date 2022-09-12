//
//  BinaryDice.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public enum BinaryDice: Equatable, Sendable {
    
    case doe(isBackward: Bool)
    case gae
    case gul
    case yut
    case mo
    
    var numberOfMove: Int {
        switch self {
        case .doe(let isBackward): return isBackward ? -1 : 1
        case .gae: return 2
        case .gul: return 3
        case .yut: return 4
        case .mo: return 5
        }
    }
}
