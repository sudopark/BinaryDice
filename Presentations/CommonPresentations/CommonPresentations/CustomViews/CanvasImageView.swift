//
//  CanvasImageView.swift
//  CommonPresentations
//
//  Created by sudo.park on 2022/10/09.
//

import UIKit


public final class CanvasImageView: UIImageView {
    
    private var drawingLayer: CALayer?
    
    public func clear() {
        self.clearFlattenedLayers()
        self.clearDrawingLayer()
        self.image = nil
    }
    
    public func drawLayers(_ layers: [CAShapeLayer]) {
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
