//
//  ViewController.swift
//  ReorderTest
//
//  Created by Mark DiFranco on 2018-03-30.
//  Copyright © 2018 Mark DiFranco. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController {
    var items = [["1", "2", "3", "4", "5", "6"], ["7", "8", "9", "10", "11", "12"], ["13", "14", "15", "16"], ["17", "18", "19", "20"]]
}

extension ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.register(CustomHeader.self, forSupplementaryViewOfKind: CustomLayout.ElementKind.header.rawValue, withReuseIdentifier: "Header")

        installsStandardGestureForInteractiveMovement = true
    }
}

extension ViewController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[section].count
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell

        cell.label.text = items[indexPath.section][indexPath.row]

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: CustomLayout.ElementKind.header.rawValue, withReuseIdentifier: "Header", for: indexPath)

        return view
    }

    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath,
                                 to destinationIndexPath: IndexPath) {
        let item = items[sourceIndexPath.section].remove(at: sourceIndexPath.row)
        items[destinationIndexPath.section].insert(item, at: destinationIndexPath.row)
    }
}
