//
//  KnightsView.swift
//  GameScene
//
//  Created by sudo.park on 2022/09/27.
//

import UIKit
import Domain
import CommonPresentations


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
        self.frame = nodeView.frame
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
        let center = nodeView.selfCenter()
        let circle = self.makeKnightLayerCircle(knight, at: center, with: nodeView.knightCircleRadius)
        self.internalImageView.drawLayers([circle])
    }
    
    private func addDoubleKnightsLayers(
        _ knights: [Knight],
        at nodeView: NodeView
    ) {
        let radius = nodeView.knightCircleRadius
        let nodeCenter = nodeView.selfCenter()
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
        let (nodeCenter, radius) = (nodeView.selfCenter(), nodeView.knightCircleRadius)
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
        let (nodeCenter, radius) = (nodeView.selfCenter(), nodeView.knightCircleRadius)
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


// MARK: - draw knights at upper side

extension KnightsView {
    
    func drawKnightsAtUpperSide(_ knights: Knights, at nodeView: NodeView) {
        self.knights = knights
        self.internalImageView.clear()
        self.frame = nodeView.frame
        switch knights.count {
        case 1: self.drawKnightAtUpperSide(knights[0], at: nodeView)
        case 2: self.drawDoubleKnightsAtUpperSide(knights, at: nodeView)
        case 3: self.drawTrippleKnightsAtUpperSide(knights, at: nodeView)
        case 4: self.drawAllKnightsAtUpperSide(knights, at: nodeView)
        default: return
        }
    }
    
    private func drawKnightAtUpperSide(_ knight: Knight, at nodeView: NodeView) {
        let (radius, nodeRadius) = (nodeView.knightCircleRadius, nodeView.frame.width/2)
        let center = nodeView.selfCenter().moved(
            dx: nodeRadius * cos(CGFloat.pi * 45/180),
            dy: -nodeRadius * sin(CGFloat.pi * 45/180)
        )
        let circle = self.makeKnightLayerCircle(knight, at: center, with: radius)
        self.internalImageView.drawLayers([circle])
    }
    
    private func drawDoubleKnightsAtUpperSide(
        _ knights: Knights,
        at nodeView: NodeView
    ) {
        let (radius, nodeCenter, nodeRadius) = (nodeView.knightCircleRadius, nodeView.selfCenter(), nodeView.frame.width/2)
        let (c45, s45) = (cos(CGFloat.pi * 45/180), sin(CGFloat.pi * 45/180))
        let refPoint = nodeCenter.moved(dx: nodeRadius * c45, dy: -nodeRadius * s45 )
        let centers: [CGPoint] = [
            refPoint.moved(dx: radius * c45, dy: radius * s45),
            refPoint.moved(dx: -radius * c45, dy: -radius * s45)
        ]
        let circles = centers.enumerated().map { (offset, center) -> CAShapeLayer in
            return self.makeKnightLayerCircle(knights[offset], at: center, with: radius)
        }
        self.internalImageView.drawLayers(circles)
    }
    
    private func drawTrippleKnightsAtUpperSide(
        _ knights: Knights,
        at nodeView: NodeView
    ) {
        let (radius, nodeCenter, nodeRadius) = (nodeView.knightCircleRadius, nodeView.selfCenter(), nodeView.frame.width/2)
        let refPoint = nodeCenter.moved(
            dx: nodeRadius * cos(CGFloat.pi * 45/180),
            dy: -nodeRadius * sin(CGFloat.pi * 45/180)
        )
        let centers: [CGPoint] = [
            refPoint,
            refPoint.moved(dy: radius * 2),
            refPoint.moved(dx: -radius * 2)
        ]
        let circles = centers.enumerated().map { (offset, center) -> CAShapeLayer in
            return self.makeKnightLayerCircle(knights[offset], at: center, with: radius)
        }
        self.internalImageView.drawLayers(circles)
    }
    
    private func drawAllKnightsAtUpperSide(
        _ knights: Knights,
        at nodeView: NodeView
    ) {
        let (radius, nodeCenter, nodeRadius) = (nodeView.knightCircleRadius, nodeView.selfCenter(), nodeView.frame.width/2)
        let refPoint = nodeCenter.moved(
            dx: nodeRadius * cos(CGFloat.pi * 45/180),
            dy: -nodeRadius * sin(CGFloat.pi * 45/180)
        )
        let centers: [CGPoint] = [
            refPoint,
            refPoint.moved(dy: radius * 2),
            refPoint.moved(dx: -radius * 2),
            refPoint.moved(dx: -radius * 2, dy: radius * 2)
        ]
        let circles = centers.enumerated().map { (offset, center) -> CAShapeLayer in
            return self.makeKnightLayerCircle(knights[offset], at: center, with: radius)
        }
        self.internalImageView.drawLayers(circles)
    }
}


// MARK: - draw knights at lower side

extension KnightsView {

    func drawKnightsAtLowerSide(_ knights: Knights, at nodeView: NodeView) {
        self.knights = knights
        self.internalImageView.clear()
        self.frame = nodeView.frame
        switch knights.count {
        case 1: self.drawKnightAtLowerSide(knights[0], at: nodeView)
        case 2: self.drawDoubleKnightsAtLowerSide(knights, at: nodeView)
        case 3: self.drawTrippleKnightsAtLowerSide(knights, at: nodeView)
        case 4: self.drawAllKnightsAtLowerSide(knights, at: nodeView)
        default: return
        }
    }
    
    private func drawKnightAtLowerSide(_ knight: Knight, at nodeView: NodeView) {
        let (radius, nodeRadius) = (nodeView.knightCircleRadius, nodeView.frame.width/2)
        let center = nodeView.center.moved(
            dx: -nodeRadius * cos(CGFloat.pi * 45/180),
            dy: nodeRadius * sin(CGFloat.pi * 45/180)
        )
        let circle = self.makeKnightLayerCircle(knight, at: center, with: radius)
        self.internalImageView.drawLayers([circle])
    }
    
    private func drawDoubleKnightsAtLowerSide(_ knights: Knights, at nodeView: NodeView) {
        let (radius, nodeCenter, nodeRadius) = (nodeView.knightCircleRadius, nodeView.selfCenter(), nodeView.frame.width/2)
        let (c45, s45) = (cos(CGFloat.pi * 45/180), sin(CGFloat.pi * 45/180))
        let refPoint = nodeCenter.moved(
            dx: -nodeRadius * cos(CGFloat.pi * 45/180),
            dy: nodeRadius * sin(CGFloat.pi * 45/180)
        )
        let centers: [CGPoint] = [
            refPoint.moved(dx: -radius * c45, dy: -radius * s45),
            refPoint.moved(dx: radius * c45, dy: radius * s45)
        ]
        let circles = centers.enumerated().map { (offset, center) -> CAShapeLayer in
            return self.makeKnightLayerCircle(knights[offset], at: center, with: radius)
        }
        self.internalImageView.drawLayers(circles)
    }
    
    private func  drawTrippleKnightsAtLowerSide(_ knights: Knights, at nodeView: NodeView) {
        let (radius, nodeCenter, nodeRadius) = (nodeView.knightCircleRadius, nodeView.selfCenter(), nodeView.frame.width/2)
        let refPoint = nodeCenter.moved(
            dx: -nodeRadius * cos(CGFloat.pi * 45/180),
            dy: nodeRadius * sin(CGFloat.pi * 45/180)
        )
        let centers: [CGPoint] = [
            refPoint,
            refPoint.moved(dy: -radius * 2),
            refPoint.moved(dx: radius * 2)
        ]
        let circles = centers.enumerated().map { (offset, center) -> CAShapeLayer in
            return self.makeKnightLayerCircle(knights[offset], at: center, with: radius)
        }
        self.internalImageView.drawLayers(circles)
    }
    
    private func drawAllKnightsAtLowerSide(
        _ knights: Knights,
        at nodeView: NodeView
    ) {
        let (radius, nodeCenter, nodeRadius) = (nodeView.knightCircleRadius, nodeView.selfCenter(), nodeView.frame.width/2)
        let refPoint = nodeCenter.moved(
            dx: -nodeRadius * cos(CGFloat.pi * 45/180),
            dy: nodeRadius * sin(CGFloat.pi * 45/180)
        )
        let centers: [CGPoint] = [
            refPoint,
            refPoint.moved(dy: -radius * 2),
            refPoint.moved(dx: radius * 2),
            refPoint.moved(dx: radius * 2, dy: -radius * 2)
        ]
        let circles = centers.enumerated().map { (offset, center) -> CAShapeLayer in
            return self.makeKnightLayerCircle(knights[offset], at: center, with: radius)
        }
        self.internalImageView.drawLayers(circles)
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

private extension Knight {
    
    func circleBackgroundColor(_ isDark: Bool) -> UIColor {
        switch (isDark, self.isDefence) {
        case (true, _): return UIColor.black
        case (false, true): return UIColor(white: 213/255, alpha: 1.0)
        case (false, false): return UIColor.white
        }
    }
}


extension NodeView {
    
    func selfCenter() -> CGPoint {
        return CGPoint.zero.moved(dx: self.frame.width/2, dy: self.frame.height/2)
    }
    
    fileprivate var knightCircleRadius: CGFloat {
        return NodeView.knightCircleRadius(self.frame.size)
    }
    
    static func knightCircleRadius(_ size: CGSize) -> CGFloat {
        return size.width / 2 * 0.4
    }
}
