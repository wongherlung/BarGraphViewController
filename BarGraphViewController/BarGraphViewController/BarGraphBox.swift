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
    
    public override init(frame: CGRect) {
        self.originalFrame = frame
        super.init(frame: frame)
    }
    
    public convenience init(frame: CGRect, item: T?, color: UIColor) {
        self.init(frame: frame)
        self.item = item
        backgroundColor = color
        self.originalColor = color
    }
    
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
}
