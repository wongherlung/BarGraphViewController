//
//  BarGraphViewController.swift
//  Pods
//
//  Created by Quoc Dat Nguyen on 3/4/16.
//
//

import UIKit

public protocol ColumnActionDelegate {
    func selectedColumnAt(columnIndex: Int)
}

public protocol BoxActionDelegate {
    /**
     Called whenever the target of a long press changes (possibly to nothing).
     */
    func longPressingAt(boxIndex: NSIndexPath?)
    /**
     Called when a long press completes.
     */
    func longPressFinished()
}

public enum AnimationDirection {
    case TopDown
    case BottomUp
    case None
}

public class BarGraphViewController<T>: UIViewController,
    UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout {
    public typealias ColorTimeFraction = (item: T?, color: UIColor?, percentage: Double)
    
    public var collectionView: UICollectionView!
    
    // Data source
    private var labels = [String]()
    private var timeRanges = [[ColorTimeFraction]]()
    
    // Data shown to user
    private var timeBoxes = [[BarGraphBox<T>]]() // Maintained as parallel array to timeRanges
    
    // Collection view sizing and arrangement variables. Reasonable defaults.
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
    private var boxActionDelegate: BoxActionDelegate?
    
    private var currentLongPressedIndex: NSIndexPath?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override public func viewDidLoad() {
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
    public func setCollectionViewDetails(frame: CGRect,
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
                                         columnActionDelegate: ColumnActionDelegate?,
                                         boxActionDelegate: BoxActionDelegate?) {
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
        self.boxActionDelegate = boxActionDelegate
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
    public func initializeCollectionView(timeRanges: [[ColorTimeFraction]], labels: [String]) {
        self.timeRanges = timeRanges
        self.timeBoxes = [[BarGraphBox<T>]](count: timeRanges.count,
                                            repeatedValue: [BarGraphBox<T>]())
        self.labels = labels
        
        let flowLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: collectionViewFrame,
                                          collectionViewLayout: flowLayout)
        collectionView.registerClass(UICollectionViewCell.self,
                                     forCellWithReuseIdentifier: "patternsCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clearColor()
        setBoxAction()
        
        view.addSubview(collectionView)
    }
    
    /**
     - Returns: A 2-dimensional array of `UIView`s, each containing a colored box in the bar graph.
     Each outer array corresponds to a column, and the inner arrays store the boxes from bottom
     to top. In other words, each box corresponds to the `ColorTimeFraction` in the corresponding
     index path in the `timeRanges` array used to initialize the collection view.
     */
    public func getTimeBoxes() -> [[BarGraphBox<T>]] {
        return timeBoxes
    }
    
    /**
     Reverts the boxes being displayed to their original display attributes.
     */
    public func revertTimeBoxes() {
        timeBoxes.flatten().forEach { timeBox in timeBox.revertAttributes() }
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func collectionView(collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return timeRanges.count
    }
    
    public func collectionView(collectionView: UICollectionView,
                               cellForItemAtIndexPath indexPath: NSIndexPath)
        -> UICollectionViewCell {
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("patternsCell",
                                                                             forIndexPath: indexPath)
            
            cell.addSubview(createCellView(cell, slotOffset: indexPath.row))
            
            return cell
    }
    
    public func collectionView(collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                                      sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: columnWidth,
                      height: lineLength + labelSize)
    }
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                                      minimumInteritemSpacingForSectionAtIndex section: Int)
        -> CGFloat {
            
            return lineSpacing
    }
    
    public func collectionView(collectionView: UICollectionView,
                               didSelectItemAtIndexPath indexPath: NSIndexPath) {
        columnActionDelegate?.selectedColumnAt(indexPath.row)
    }
    
    // MARK: - Design
    
    private func createCellView(cell: UICollectionViewCell, slotOffset: Int) -> UIView {
        let lineData = timeRanges[slotOffset]
        
        let parentView = UIView(frame: CGRect(x: 0, y: 0,
            width: cell.frame.width, height: cell.frame.height))
        parentView.addSubview(getLineView(parentView, lineData: lineData, slotOffset: slotOffset))
        parentView.addSubview(getLabelView(parentView,
            label: labels[slotOffset % labels.count])) // Repeating labels if not enough.
        return parentView
    }
    
    private func getLineView(parentView: UIView,
                             lineData: [ColorTimeFraction],
                             slotOffset: Int) -> UIView {
        let totalHeight = lineLength
        
        let bucketView = UIView(frame: CGRect(
            x: (parentView.frame.width - lineWidth) / 2,
            y: 0,
            width: lineWidth,
            height: lineLength))
        
        timeBoxes[slotOffset] = [BarGraphBox<T>]()
        var runningTotal: CGFloat = 0.0
        
        for range in lineData {
            let rangeViewHeight = totalHeight * CGFloat(range.percentage)
            let rangeViewY = totalHeight - runningTotal * totalHeight - rangeViewHeight
            runningTotal += CGFloat(range.percentage)
            
            let keyframes = animationKeyframes(totalHeight,
                                               boxHeight: rangeViewHeight,
                                               boxWidth: bucketView.frame.width,
                                               boxY: rangeViewY)
            let rangeView = BarGraphBox<T>(frame: keyframes.start,
                                           item: range.item,
                                           color: range.color ?? defaultColor)
            bucketView.addSubview(rangeView)
            timeBoxes[slotOffset].append(rangeView)
            
            if animationDirection != .None {
                UIView.animateWithDuration(animationDuration, animations: {
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
    
    // MARK: - Interactions
    
    private func setBoxAction() {
        let longPressRecognizer = UILongPressGestureRecognizer()
        longPressRecognizer.addTarget(self, action: #selector(boxLongPressed(_:)))
        collectionView.addGestureRecognizer(longPressRecognizer)
    }
    
    public func boxLongPressed(longPressRecognizer: UILongPressGestureRecognizer) {
        guard longPressRecognizer.state != .Ended else {
            boxActionDelegate?.longPressFinished()
            currentLongPressedIndex = nil
            return
        }
        
        let pressedBoxIndexPath = determinePressedBox(longPressRecognizer)
        
        guard pressedBoxIndexPath != currentLongPressedIndex else {
            return
        }
        
        boxActionDelegate?.longPressingAt(pressedBoxIndexPath)
        currentLongPressedIndex = pressedBoxIndexPath
    }
    
    /**
     - Returns: The index path in `timeBoxes` to the pressed box via `timeBoxes[section][row]`, or
     `nil` if no box is pressed
     */
    private func determinePressedBox(longPressRecognizer: UILongPressGestureRecognizer)
        -> NSIndexPath? {
            guard let indexPath = collectionView
                .indexPathForItemAtPoint(longPressRecognizer.locationInView(collectionView)) else {
                    return nil
            }
            
            let yCoordinateInCell = longPressRecognizer.locationInView(collectionView).y
            
            guard let pressedBox = timeBoxes[indexPath.row].enumerate().filter({ index, barGraphBox in
                return barGraphBox.frame.minY <= yCoordinateInCell
                    && barGraphBox.frame.maxY >= yCoordinateInCell
            }).first else {
                return nil
            }
            
            return NSIndexPath(forRow: pressedBox.index, inSection: indexPath.row)
    }
}