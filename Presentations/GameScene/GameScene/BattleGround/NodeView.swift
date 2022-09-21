//
//  NodeView.swift
//  GameScene
//
//  Created by sudo.park on 2022/09/22.
//

import UIKit
import Domain
import CommonPresentations


final class NodeView: BaseUIView {
    
    let node: Node
    private var borderLayer: CAShapeLayer!
    
    init(node: Node) {
        self.node = node
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateBorderMaskLayer()
    }
}


extension NodeView {
    
    private func updateBorderMaskLayer() {
        if self.borderLayer == nil {
            self.addBorderLayer()
        }
        guard self.borderLayer.frame != self.bounds else { return }
        self.borderLayer.frame = self.bounds
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.bounds.width/2)
        self.borderLayer.path = path.cgPath
    }
    
    private func addBorderLayer() {
        let borderLayer = CAShapeLayer()
        
        borderLayer.strokeColor = UIColor.black.cgColor
        borderLayer.lineWidth = 1.5
        borderLayer.lineCap = .round
        borderLayer.lineJoin = .round
        borderLayer.lineDashPattern = [1, 2]
    
        self.layer.addSublayer(borderLayer)
        self.borderLayer = borderLayer
    }
}
