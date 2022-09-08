//
//  Array+extension.swift
//  Domain
//
//  Created by sudo.park on 2022/09/08.
//

import Foundation


extension Array {
    
    public subscript(safe index: Index) -> Element? {
        guard (0..<self.count) ~= index else { return nil }
        return self[index]
    }
}
