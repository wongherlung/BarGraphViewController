//
//  BarGraphBox.swift
//  Pods
//
//  Created by Quoc Dat Nguyen on 30/6/16.
//
//

import UIKit

public class BarGraphBox<T>: UIView {
    public var item: T? = nil
    var originalColor: UIColor = UIColor.clearColor()
    var originalFrame: CGRect
    var maxHeight: CGFloat
    var animationDuration: NSTimeInterval = 0
    
    public override init(frame: CGRect) {
        self.originalFrame = frame
        self.maxHeight = originalFrame.height
        super.init(frame: frame)
    }
    
    public convenience init(frame: CGRect, item: T?, color: UIColor, maxHeight: CGFloat,
                            animationDuration: NSTimeInterval) {
        self.init(frame: frame)
        self.item = item
        backgroundColor = color
        self.originalColor = color
        self.maxHeight = maxHeight
        self.animationDuration = animationDuration
    }
    
    // MARK: - Multicolor
    
    public func revertColor() {
        backgroundColor = originalColor
    }
    
    public func revertFrame() {
        frame = originalFrame
    }
    
    public func revertAttributes() {
        revertColor()
        revertFrame()
    }
    
    // MARK: Single-color
    
    public func animateToPercentage(percentage: Double) {
        let targetHeight = maxHeight * CGFloat(percentage)
        let targetFrame = CGRect(x: frame.minX, y: frame.maxY - targetHeight,
                                 width: frame.width, height: targetHeight)
        UIView.animateWithDuration(animationDuration,
                                   animations: { self.frame = targetFrame },
                                   completion: nil)
    }
}
