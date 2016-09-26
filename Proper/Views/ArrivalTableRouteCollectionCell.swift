//
//  ArrivalTableRouteCollectionCell.swift
//  Proper
//
//  Created by Elliott Williams on 9/22/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit

class ArrivalTableRouteCollectionCell: UITableViewCell {
    @IBOutlet var collectionView: UICollectionView!

    func bind<D: protocol<UICollectionViewDelegate, UICollectionViewDataSource>>(source: D) {
        collectionView.dataSource = source
        collectionView.delegate = source
        collectionView.reloadData()
    }
}
