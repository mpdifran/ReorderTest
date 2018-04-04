//
//  CustomLayout.swift
//  ReorderTest
//
//  Created by Mark DiFranco on 2018-04-04.
//  Copyright © 2018 Mark DiFranco. All rights reserved.
//

import UIKit

// MARK: - CustomLayout

class CustomLayout: UICollectionViewLayout {

    enum ElementKind: String {
        case header = "CustomLayout.ElementKind.header"
    }

    var sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 10, right: 20)
    var interitemSpacing: CGFloat = 10

    var headerHeight: CGFloat = 50
    var minCellDimension: CGFloat = 100

    fileprivate var layoutFrames = LayoutFrames()
    fileprivate var itemCounts = [Int]()
    fileprivate var numberOfSections: Int { return itemCounts.count }
    fileprivate var contentSize = CGSize.zero
}

// MARK: Public Methods

extension CustomLayout {

    func scrollItemToVisible(at indexPath: IndexPath) {
        let frame = layoutFrames.sections[indexPath.section].itemFrames[indexPath.item]

        collectionView?.scrollRectToVisible(frame, animated: true)
    }

    func sectionSize(forWidth width: CGFloat, numberOfItems: UInt, maxNumberOfRows: UInt) -> CGSize {
        guard numberOfItems > 0 else { return .zero }

        let bounds = CGRect(x: 0, y: 0, width: width, height: 0)
        let (cellDimension, numberOfColumns) = calculateHorizontalCellPositioning(inBounds: bounds)

        let numberOfRows = min(maxNumberOfRows, ((numberOfItems - 1) / numberOfColumns) + 1)

        let cellHeights = CGFloat(numberOfRows) * cellDimension
        let cellSpacing = interitemSpacing * CGFloat(numberOfRows - 1)
        let sectionInsets = sectionInset.top + sectionInset.bottom

        return CGSize(width: width, height: cellHeights + cellSpacing + sectionInsets)
    }

    func fetchIndexPath(forItemAtPoint point: CGPoint) -> IndexPath? {
        for (sectionIndex, section) in layoutFrames.sections.enumerated() {
            for (itemIndex, itemFrames) in section.itemFrames.enumerated() {
                guard itemFrames.contains(point) else { continue }

                return IndexPath(item: itemIndex, section: sectionIndex)
            }
        }
        return nil
    }
}

// MARK: Layout Invalidation Methods

extension CustomLayout {

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }

        return newBounds.width != collectionView.bounds.width
    }
}

// MARK: Layout Methods

extension CustomLayout {

    override var collectionViewContentSize: CGSize { return contentSize }

    override func prepare() {
        super.prepare()

        calculateItemCounts()
        calculateItemFrames()
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard layoutFrames.sections.count > 0 else { return [] }

        var layoutAttributes = [UICollectionViewLayoutAttributes]()

        // Sections
        for (sectionIndex, section) in layoutFrames.sections.enumerated() {
            if section.headerFrame.intersects(rect) {
                let indexPath = IndexPath(item: 0, section: sectionIndex)
                if let attributes = layoutAttributesForSupplementaryView(ofKind: .header, at: indexPath) {
                    layoutAttributes.append(attributes)
                }
            }

            // Items
            for (itemIndex, itemFrame) in section.itemFrames.enumerated() {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                if itemFrame.intersects(rect) {
                    if let attributes = layoutAttributesForItem(at: indexPath) {
                        layoutAttributes.append(attributes)
                    }
                }
            }
        }

        return layoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let itemFrame = layoutFrames.sections[indexPath.section].itemFrames[indexPath.item]

        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        attributes.frame = itemFrame

        return attributes
    }

    func layoutAttributesForSupplementaryView(ofKind elementKind: ElementKind,
                                              at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributesForSupplementaryView(ofKind: elementKind.rawValue, at: indexPath)
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                       at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let kind = ElementKind(rawValue: elementKind) else { fatalError("Unknown supplementary view type") }

        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)

        switch kind {
        case .header:
            attributes.frame = layoutFrames.sections[indexPath.section].headerFrame
        }

        return attributes
    }

    override func layoutAttributesForInteractivelyMovingItem(at indexPath: IndexPath,
                                                             withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
        print("Indexpath: \(indexPath) targetPosition: \(position)")
        let attributes = super.layoutAttributesForInteractivelyMovingItem(at: indexPath, withTargetPosition: position)

        attributes.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 8))

        return attributes
    }
}

// MARK: Private Methods

private extension CustomLayout {

    var safeRect: CGRect {
        guard let collectionView = collectionView else { return .zero }

        var bounds = collectionView.bounds
        bounds.origin = .zero
        return UIEdgeInsetsInsetRect(bounds, collectionView.safeAreaInsets)
    }

    func calculateItemCounts() {
        itemCounts.removeAll(keepingCapacity: true)

        guard let collectionView = collectionView else { return }
        let sections = collectionView.dataSource?.numberOfSections?(in: collectionView) ?? 1

        for section in 0 ..< sections {
            guard let items = collectionView.dataSource?
                .collectionView(collectionView, numberOfItemsInSection: section) else { continue }
            guard items >= 0 else { fatalError("Cannot return a negative count for number of items in section \(section)") }

            itemCounts.append(items)
        }
    }

    func calculateItemFrames() {
        layoutFrames = LayoutFrames()
        var offset = CGPoint(x: safeRect.origin.x, y: interitemSpacing)

        for section in 0 ..< numberOfSections {
            let (sectionFrames, sectionSize) = calculateItemFrames(forSection: section, withOffset: offset)
            layoutFrames.sections.append(sectionFrames)
            offset.y += sectionSize.height
        }

        let width = safeRect.width
        let height = offset.y
        contentSize = CGSize(width: width, height: height)
    }

    private func calculateItemFrames(forSection section: Int, withOffset offset: CGPoint) -> (LayoutFrames.Section, CGSize) {
        // Header
        let headerFrame = CGRect(x: offset.x, y: offset.y, width: safeRect.width, height: headerHeight)

        // Items
        let numberOfItems = itemCounts[section]
        let (cellDimension, numberOfColumns) = calculateHorizontalCellPositioning(inBounds: safeRect)

        let headerOffset: CGFloat
        if headerFrame.height > 0 {
            headerOffset = headerFrame.maxY + interitemSpacing
        } else {
            headerOffset = 0
        }
        var maximumY = headerOffset
        var itemFrames = [CGRect]()
        for index: UInt in 0 ..< UInt(numberOfItems) {
            let x = CGFloat(index % numberOfColumns) * (cellDimension + interitemSpacing) + sectionInset.left + offset.x
            let y = CGFloat(index / numberOfColumns) * (cellDimension + interitemSpacing) + sectionInset.top + headerOffset

            let frame = CGRect(x: x, y: y, width: cellDimension, height: cellDimension)
            itemFrames.append(frame)
            maximumY = frame.maxY
        }

        // Section
        let sectionWidth = safeRect.width
        let sectionHeight = maximumY + sectionInset.bottom - offset.y
        let sectionFrames = LayoutFrames.Section(headerFrame, itemFrames)
        let sectionSize = CGSize(width: sectionWidth, height: sectionHeight)

        return (sectionFrames, sectionSize)
    }

    private func calculateHorizontalCellPositioning(inBounds
        bounds: CGRect) -> (cellDimension: CGFloat, numberOfColumns: UInt) {

        let availableWidth = bounds.width - sectionInset.left - sectionInset.right
        let numberOfColumns = UInt(floor(availableWidth / (minCellDimension + interitemSpacing)))

        let remainingWidth = availableWidth - CGFloat(numberOfColumns - 1) * interitemSpacing
        let cellDimension = round(remainingWidth / CGFloat(numberOfColumns))

        return (cellDimension, numberOfColumns)
    }
}

// MARK: - LayoutFrames

private struct LayoutFrames {
    var sections: [Section]

    init(sections: [Section] = [Section]()) {
        self.sections = sections
    }

    // MARK: Section

    struct Section {
        let headerFrame: CGRect
        let itemFrames: [CGRect]

        init(_ headerFrame: CGRect = .zero, _ itemFrames: [CGRect] = [CGRect]()) {
            self.headerFrame = headerFrame
            self.itemFrames = itemFrames
        }
    }
}
