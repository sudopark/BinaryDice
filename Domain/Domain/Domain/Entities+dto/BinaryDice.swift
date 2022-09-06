//
//  BinaryDice.swift
//  Domain
//
//  Created by sudo.park on 2022/09/05.
//

import Foundation


public enum BinaryDice {
    
    case doe(isBackward: Bool)
    case gae
    case gul
    case yut
    case mo
    
    static func roll() -> Self {
        let yuts = Array(repeating: Bool.random(), count: 4)
        let openCount = yuts.filter { $0 == true }.count
        switch openCount {
        case 0:
            return .mo
        case 1:
            return .gul
        case 2:
            return .gae
        case 3:
            let isBackward = yuts.first == false
            return .doe(isBackward: isBackward)
        default:
            return .yut
        }
    }
    
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
