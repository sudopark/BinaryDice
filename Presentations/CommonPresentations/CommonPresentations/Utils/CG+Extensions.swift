//
//  CGFloat+Extensions.swift
//  CommonPresentations
//
//  Created by sudo.park on 2022/10/09.
//

import UIKit


extension CGPoint {
    
    public func moved(dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint {
        return .init(x: self.x + dx, y: self.y + dy)
    }
}


extension CGSize {
    
    public init(square length: CGFloat) {
        self.init(width: length, height: length)
    }
}
