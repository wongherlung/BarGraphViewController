//
//  PatternsStatisticsController.swift
//  Zone
//
//  Created by Quoc Dat Nguyen on 3/4/16.
//  Copyright © 2016 nus.cs3217.group8. All rights reserved.
//

import UIKit

public protocol ColumnActionDelegate {
    func selectedColumnAt(_ columnIndex: Int)
}

open class BarGraphViewController: UIViewController,
                                     UICollectionViewDataSource,
                                     UICollectionViewDelegateFlowLayout {
    public typealias ColorTimeFraction = (color: UIColor?, percentage: Double)
    
    public enum AnimationDirection {
        case topDown
        case bottomUp
        case none
    }
    
    open var collectionView: UICollectionView!
    
    // Data source
    fileprivate var labels = [String]()
    fileprivate var timeRanges = [[ColorTimeFraction]]()
    
    // Collection view sizing and arrangement variables. Reasonable defaults.
    fileprivate var collectionViewFrame = CGRect.zero
    fileprivate var lineLength = CGFloat.nan
    fileprivate var labelSize = CGFloat.nan
    fileprivate var lineWidth = CGFloat.nan
    fileprivate var columnWidth = CGFloat.nan
    fileprivate var lineSpacing = CGFloat.nan
    fileprivate var labelFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    fileprivate var labelColor = UIColor.black
    fileprivate var defaultColor = UIColor.clear
    fileprivate var animationDuration = Double.infinity
    fileprivate var animationDirection = AnimationDirection.none
    fileprivate var columnActionDelegate: ColumnActionDelegate?
    
    fileprivate var boxes = [UIView]()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /**
     * Sets layout, sizing and animation details for the bar graph.
     *
     * - Parameter frame: The bar graph's frame. Set to `CGRectZero` if using auto layout.
     * - Parameter lineLength: The length of each bar in the bar graph.
     * - Parameter labelSize: The height and width of each label in the bar graph.
     * - Parameter lineWidth: The width of each bar in the bar graph.
     * - Parameter columnWidth: The width of each column (bar and label).
     * - Parameter lineSpacing: The spacing between each column.
     * - Parameter labelFont: The font used to display the labels.
     * - Parameter labelColor: The text color of the labels.
     * - Parameter defaultColor: The color used to fill up the time fraction if the color is not
     * specified.
     * - Parameter animationDirection: The direction in which the bars are to grow from.
     * - Parameter animationDuration: The animation duration of each bar. Does not matter if
     * `animationDirection` is `.None`.
     * - Parameter columnActionDelegate: The delegate to react to the event of a column being
     * selected.
     */
    open func setCollectionViewDetails(_ frame: CGRect,
                                         lineLength: CGFloat,
                                         labelSize: CGFloat,
                                         lineWidth: CGFloat,
                                         columnWidth: CGFloat,
                                         lineSpacing: CGFloat,
                                         labelFont: UIFont,
                                         labelColor: UIColor,
                                         defaultColor: UIColor,
                                         animationDirection: AnimationDirection,
                                         animationDuration: TimeInterval,
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
    
    /**
     * Sets the data for the bar graph, and generates it with animations. Should only be called
     * after `setCollectionViewDetails` has been called.
     *
     * - Parameter timeRanges: Each outer array represents one bar, and each element in the inner
     * array represents one box in the bar graph.
     * - Parameter labels: Labels to be displayed under each column. Cycles around if there are not
     * enough labels for all columns.
     */
    open func initializeCollectionView(_ timeRanges: [[ColorTimeFraction]], labels: [String]) {
        self.timeRanges = timeRanges
        self.labels = labels
        
        let flowLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: collectionViewFrame,
                                          collectionViewLayout: flowLayout)
        collectionView.register(UICollectionViewCell.self,
                                     forCellWithReuseIdentifier: "patternsCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clear
        
        view.addSubview(collectionView)
    }
    
    // MARK: - UICollectionViewDataSource
    
    open func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return timeRanges.count
    }
    
    open func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "patternsCell",
                                                                         for: indexPath)
        
        cell.addSubview(createCellView(cell, slotOffset: (indexPath as NSIndexPath).row))
        
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                                      sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: columnWidth,
                      height: lineLength + labelSize)
    }
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                                      minimumInteritemSpacingForSectionAt section: Int)
        -> CGFloat {
        
        return lineSpacing
    }
    
    open func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        columnActionDelegate?.selectedColumnAt((indexPath as NSIndexPath).row)
    }
    
    // MARK: - Design
    
    fileprivate func createCellView(_ cell: UICollectionViewCell, slotOffset: Int) -> UIView {
        let lineData = timeRanges[slotOffset]
        
        let parentView = UIView(frame: CGRect(x: 0, y: 0,
            width: cell.frame.width, height: cell.frame.height))
        parentView.addSubview(getLineView(parentView, lineData: lineData))
        parentView.addSubview(getLabelView(parentView,
            label: labels[slotOffset % labels.count])) // Repeating labels if not enough.
        return parentView
    }
    
    fileprivate func getLineView(_ parentView: UIView, lineData: [ColorTimeFraction]) -> UIView {
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
            
            if animationDirection != .none {
                UIView.animate(withDuration: animationDuration, animations: {
                    rangeView.frame = keyframes.end
                })
            }
        }
        return bucketView
    }
    
    /**
     * Creates the initial and final frames for each box in the bar graph.
     * If the animation mode is `.None`, the initial and final frames are the same.
     */
    fileprivate func animationKeyframes(_ bottomY: CGFloat,
                                    boxHeight: CGFloat,
                                    boxWidth: CGFloat,
                                    boxY: CGFloat) -> (start: CGRect, end: CGRect) {
        let startY = animationDirection == .topDown ? 0 :
            animationDirection == .bottomUp ? bottomY : boxY
        let start = CGRect(x: 0,
                           y: startY,
                           width: boxWidth,
                           height: animationDirection == .none ? boxHeight : 0)
        let end = CGRect(x: 0,
                         y: boxY,
                         width: boxWidth,
                         height: boxHeight)
        return (start, end)
    }
    
    fileprivate func getLabelView(_ parentView: UIView, label: String) -> UIView {
        let labelView = UILabel(frame:
            CGRect(x: 0, y: parentView.frame.height - labelSize,
                width: parentView.frame.width, height: labelSize))
        labelView.text = label
        labelView.textAlignment = .center
        labelView.font = labelFont
        labelView.textColor = labelColor
        return labelView
    }
}
