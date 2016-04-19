//
//  PatternsStatisticsController.swift
//  Zone
//
//  Created by Quoc Dat Nguyen on 3/4/16.
//  Copyright © 2016 nus.cs3217.group8. All rights reserved.
//

import UIKit

protocol ColumnActionDelegate {
    func selectedColumnAt(columnIndex: Int)
}

class BarGraphViewController: UIViewController,
                              UICollectionViewDataSource,
                              UICollectionViewDelegateFlowLayout {
    typealias ColorTimeFraction = (color: UIColor?, percentage: Double)
    
    enum AnimationDirection {
        case TopDown
        case BottomUp
        case None
    }
    
    private var labels = [String]()
    private var timeRanges = [[ColorTimeFraction]]()
    
    // Collection view sizing and arrangement variables. Reasonable defaults.
    var collectionView: UICollectionView!
    private var collectionViewFrame = CGRectZero
    private var lineLength = CGFloat.NaN
    private var labelSize = CGFloat.NaN
    private var lineWidth = CGFloat.NaN
    private var columnWidth = CGFloat.NaN
    private var lineSpacing = CGFloat.NaN
    private var labelFont = UIFont.systemFontOfSize(UIFont.systemFontSize())
    private var labelColor = UIColor.blackColor()
    private var defaultColor = UIColor.clearColor()
    private var animationDuration = Double.infinity
    private var animationDirection = AnimationDirection.None
    private var columnActionDelegate: ColumnActionDelegate?
    
    private var boxes = [UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setCollectionViewDetails(frame: CGRect,
                                 lineLength: CGFloat,
                                 labelSize: CGFloat,
                                 lineWidth: CGFloat,
                                 columnWidth: CGFloat,
                                 lineSpacing: CGFloat,
                                 labelFont: UIFont,
                                 labelColor: UIColor,
                                 defaultColor: UIColor,
                                 animationDirection: AnimationDirection,
                                 animationDuration: NSTimeInterval,
                                 columnActionDelegate: ColumnActionDelegate?) {
        self.collectionViewFrame = frame
        self.lineLength = lineLength
        self.labelSize = labelSize
        self.lineWidth = lineWidth
        self.columnWidth = columnWidth
        self.lineSpacing = lineSpacing
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.defaultColor = defaultColor
        self.animationDirection = animationDirection
        self.animationDuration = animationDuration
        
        self.columnActionDelegate = columnActionDelegate
    }
    
    func initializeCollectionView(timeRanges: [[ColorTimeFraction]], labels: [String]) {
        self.timeRanges = timeRanges
        self.labels = labels
        
        let flowLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: collectionViewFrame,
                                          collectionViewLayout: flowLayout)
        collectionView.registerClass(UICollectionViewCell.self,
                                     forCellWithReuseIdentifier: "patternsCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clearColor()
        
        view.addSubview(collectionView)
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return timeRanges.count
    }
    
    func collectionView(collectionView: UICollectionView,
                        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("patternsCell",
                                                                         forIndexPath: indexPath)
        
        cell.addSubview(createCellView(cell, slotOffset: indexPath.row))
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: columnWidth,
                      height: lineLength + labelSize)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return lineSpacing
    }
    
    func collectionView(collectionView: UICollectionView,
                        didSelectItemAtIndexPath indexPath: NSIndexPath) {
        columnActionDelegate?.selectedColumnAt(indexPath.row)
    }
    
    // MARK: - Design
    
    private func createCellView(cell: UICollectionViewCell, slotOffset: Int) -> UIView {
        let lineData = timeRanges[slotOffset]
        
        let parentView = UIView(frame: CGRect(x: 0, y: 0,
            width: cell.frame.width, height: cell.frame.height))
        parentView.addSubview(getLineView(parentView, lineData: lineData))
        parentView.addSubview(getLabelView(parentView,
            label: labels[slotOffset % labels.count])) // Repeating labels if not enough.
        return parentView
    }
    
    private func getLineView(parentView: UIView, lineData: [ColorTimeFraction]) -> UIView {
        let totalHeight = lineLength
        
        let bucketView = UIView(frame: CGRect(
            x: (parentView.frame.width - lineWidth) / 2,
            y: 0,
            width: lineWidth,
            height: lineLength))
        
        var runningTotal: CGFloat = 0.0
        for range in lineData {
            let rangeViewHeight = totalHeight * CGFloat(range.percentage)
            let rangeViewY = totalHeight - runningTotal * totalHeight - rangeViewHeight
            runningTotal += CGFloat(range.percentage)
            
            let keyframes = animationKeyframes(totalHeight,
                                               boxHeight: rangeViewHeight,
                                               boxWidth: bucketView.frame.width,
                                               boxY: rangeViewY)
            let rangeView = UIView(frame: keyframes.start)
            rangeView.backgroundColor = range.color ?? defaultColor
            bucketView.addSubview(rangeView)
            if animationDirection != .None {
                UIView.animateWithDuration(animationDuration, animations: {
                    rangeView.frame = keyframes.end
                })
            }
            /*let rangeViewFrame = CGRect(x: 0,
                                        y: rangeViewY,
                                        width: bucketView.frame.width,
                                        height: rangeViewHeight)
            let rangeView = UIView(frame: CGRect(x: 0,
                y: totalHeight,
                width: rangeViewFrame.width,
                height: 0))
            rangeView.backgroundColor = range.color ?? defaultColor
            runningTotal += CGFloat(range.percentage)
            bucketView.addSubview(rangeView)
            UIView.animateWithDuration(0.5, animations: {
                rangeView.frame = rangeViewFrame
            })*/
        }
        return bucketView
    }
    
    private func animationKeyframes(bottomY: CGFloat,
                                    boxHeight: CGFloat,
                                    boxWidth: CGFloat,
                                    boxY: CGFloat) -> (start: CGRect, end: CGRect) {
        let startY = animationDirection == .TopDown ? 0 :
            animationDirection == .BottomUp ? bottomY : boxY
        let start = CGRect(x: 0,
                           y: startY,
                           width: boxWidth,
                           height: animationDirection == .None ? boxHeight : 0)
        let end = CGRect(x: 0,
                         y: boxY,
                         width: boxWidth,
                         height: boxHeight)
        return (start, end)
    }
    
    private func getLabelView(parentView: UIView, label: String) -> UIView {
        let labelView = UILabel(frame:
            CGRect(x: 0, y: parentView.frame.height - labelSize,
                width: parentView.frame.width, height: labelSize))
        labelView.text = label
        labelView.textAlignment = .Center
        labelView.font = labelFont
        labelView.textColor = labelColor
        return labelView
    }
}
