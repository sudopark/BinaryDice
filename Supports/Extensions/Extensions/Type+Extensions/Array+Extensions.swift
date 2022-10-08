//
//  Array+Extensions.swift
//  Extensions
//
//  Created by sudo.park on 2022/09/11.
//

import Foundation


extension Array {
    
    public subscript(safe index: Index) -> Element? {
        guard (0..<self.count) ~= index else { return nil }
        return self[index]
    }
    
    public func asDictionary<K: Hashable>(_ keySelector: (Element) -> K) -> [K: Element] {
        return self.reduce(into: [K: Element]()) { $0[keySelector($1)] = $1 }
    }
}
