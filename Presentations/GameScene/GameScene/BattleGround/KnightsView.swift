//
//  KnightsView.swift
//  GameScene
//
//  Created by sudo.park on 2022/09/27.
//

import UIKit
import Domain
import CommonPresentations


private final class CanvasImageView: UIImageView {
    
    private var drawingLayer: CALayer?
    
    func clear() {
        self.clearFlattenedLayers()
        self.clearDrawingLayer()
        self.image = nil
    }
    
    func drawLayers(_ layers: [CAShapeLayer]) {
        self.setupDrawingLayerIfNeed()
        layers.forEach {
            self.drawingLayer?.addSublayer($0)
        }
        self.flattenToImage()
    }
    
    private func flattenToImage() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        defer {
            self.clearFlattenedLayers()
            UIGraphicsEndImageContext()
        }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        if let image = self.image {
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        }
        drawingLayer?.render(in: context)
        let output = UIGraphicsGetImageFromCurrentImageContext()
        self.image = output
    }
    
    private func clearFlattenedLayers() {
        for case let shapeLayer in self.drawingLayer?.sublayers ?? [] {
            shapeLayer.removeFromSuperlayer()
        }
    }
    
    private func clearDrawingLayer() {
        self.drawingLayer?.removeFromSuperlayer()
        self.drawingLayer = nil
    }
    
    private func setupDrawingLayerIfNeed() {
        guard self.drawingLayer == nil else { return }
        let subLayer = CALayer()
        subLayer.contentsScale = UIScreen.main.scale
        self.layer.addSublayer(subLayer)
        self.drawingLayer = subLayer
    }
}

final class KnightsView: BaseUIView {
    
    private let internalImageView = CanvasImageView()
    
    private let isDark: Bool
    
    private var knights: Knights?
    
    init(isDark: Bool) {
        self.isDark = isDark
        super.init(frame: .zero)
        self.setupLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
       
    private func setupLayouts() {
        self.addSubview(internalImageView)
        internalImageView.autoLayout.fill(self)
    }
}


// MARK: - draw single side knights

extension KnightsView {
    
    func drawKnights(_ knights: Knights, at nodeView: NodeView) {
        self.knights = knights
        self.internalImageView.clear()
        switch knights.count {
        case 1: self.addSingleKnightLayer(knights[0], at: nodeView)
        case 2: self.addDoubleKnightsLayers(knights, at: nodeView)
        case 3: self.addTrippleKnightsLayers(knights, at: nodeView)
        case 4: self.addAllKnightsLayers(knights, at: nodeView)
        default: return
        }
    }
    
    private func addSingleKnightLayer(
        _ knight: Knight,
        at nodeView: NodeView
    ) {
        let center = nodeView.center
        let circle = self.makeKnightLayerCircle(knight, at: center, with: nodeView.knightCircleRadius)
        self.internalImageView.drawLayers([circle])
    }
    
    private func addDoubleKnightsLayers(
        _ knights: [Knight],
        at nodeView: NodeView
    ) {
        let radius = nodeView.knightCircleRadius
        let nodeCenter = nodeView.center
        let circleCenters: [CGPoint] = [
            nodeCenter.moved(dx: -radius), nodeCenter.moved(dx: radius)
        ]
        let circles = circleCenters.enumerated().map { (offset, center) in
            return self.makeKnightLayerCircle(knights[offset], at: center, with: radius)
        }
        self.internalImageView.drawLayers(circles)
    }
    
    private func addTrippleKnightsLayers(
        _ knights: [Knight],
        at nodeView: NodeView
    ) {
        let (nodeCenter, radius) = (nodeView.center, nodeView.knightCircleRadius)
        let (sin60, cos60) = (sin(1/3 * CGFloat.pi), cos(1/3 * CGFloat.pi))
        let joinCircleRadius = (1-sin60) * radius / sin60
        let (dx, dy) = (sin60 * (radius + joinCircleRadius), cos60 * (radius + joinCircleRadius))
        let centers: [CGPoint] = [
            nodeCenter.moved(dy: -radius-joinCircleRadius),
            nodeCenter.moved(dx: -dx, dy: dy),
            nodeCenter.moved(dx: dx, dy: dy)
        ]
        let circles = centers.enumerated().map { (offset, center) in
            return self.makeKnightLayerCircle(knights[offset], at: center, with: radius)
        }
        self.internalImageView.drawLayers(circles)
    }
    
    private func addAllKnightsLayers(
        _ knights: [Knight],
        at nodeView: NodeView
    ) {
        let defender = knights.first(where: { $0.isDefence }) ?? knights[0]
        let attackers = knights.filter { $0.id != defender.id }
        let (nodeCenter, radius) = (nodeView.center, nodeView.knightCircleRadius)
        let defenderCircle = self.makeKnightLayerCircle(defender, at: nodeCenter, with: radius)
        
        let (dx, dy) = (sin(1/3 * CGFloat.pi) * radius * 2, cos(1/3 * CGFloat.pi * radius * 2))
        let attackerCenters: [CGPoint] = [
            nodeCenter.moved(dy: -2 * radius),
            nodeCenter.moved(dx: -dx, dy: dy),
            nodeCenter.moved(dx: dx, dy: dy)
        ]
        let attackerCircles = attackerCenters.enumerated().map { (offset, center) in
            return self.makeKnightLayerCircle(attackers[offset], at: center, with: radius)
        }
        self.internalImageView.drawLayers([defenderCircle] + attackerCircles)
    }
    
    private func makeKnightLayerCircle(
        _ knight: Knight,
        at center: CGPoint,
        with radius: CGFloat
    ) -> CAShapeLayer {
        let color = knight.circleBackgroundColor(self.isDark)
        let circle: CAShapeLayer = .circle(center, radius, color)
        guard knight.isDefence
        else {
            return circle
        }
        
        let innerCircleRadius = radius * 0.45
        let innerColor = self.isDark ? UIColor.white : UIColor.black
        let innerCircle: CAShapeLayer = .circle(center, innerCircleRadius, innerColor)
        circle.addSublayer(innerCircle)
        return circle
    }
}

private extension CAShapeLayer {
    
    static func circle(
        _ center: CGPoint,
        _ radius: CGFloat,
        _ color: UIColor
    ) -> CAShapeLayer {
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        let sender = CAShapeLayer()
        sender.path = path.cgPath
        sender.backgroundColor = color.cgColor
        return sender
    }
}

private extension CGPoint {
    
    func moved(dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint {
        return .init(x: self.x + dx, y: self.y + dy)
    }
}

private extension Knight {
    
    func circleBackgroundColor(_ isDark: Bool) -> UIColor {
        switch (isDark, self.isDefence) {
        case (true, _): return UIColor.black
        case (false, true): return UIColor(white: 213/255, alpha: 1.0)
        case (false, false): return UIColor.white
        }
    }
}


private extension NodeView {
    
    var knightCircleRadius: CGFloat {
        return self.frame.width / 2 * 0.4
    }
}
