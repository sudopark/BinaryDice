//
//  RandDomiceRoller.swift.swift
//  Domain
//
//  Created by sudo.park on 2022/09/12.
//

import Foundation


public protocol RandDomiceRoller: Sendable {
    
    func roll() -> BinaryDice
}


public struct DiceRollerImple: RandDomiceRoller {
    
    public func roll() -> BinaryDice {
        let dices = Array(repeating: Bool.random(), count: 4)
        let backwardDiceIndex = Int.random(in: 0...3)
        let positiveDiceCount = dices.filter { $0 }.count
        switch positiveDiceCount {
        case 0:
            return .mo
        case 1:
            return .gul
        case 2:
            return .gae
        case 3:
            let isBackward = dices[backwardDiceIndex] == false
            return .doe(isBackward: isBackward)
        default:
            return .yut
        }
    }
}

