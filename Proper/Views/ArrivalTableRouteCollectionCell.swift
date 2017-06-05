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

  override func awakeFromNib() {
    super.awakeFromNib()
    // Declares `badgeCell` as the reusable cell for the collection view. `RoutesCollectionViewModel` dequeues cells
    // with identifier `badgeCell`.
    collectionView.register(UINib(nibName: "RoutesCollectionBadgeCell", bundle: Bundle.main),
                            forCellWithReuseIdentifier: "badgeCell")
  }

  func bind<D: UICollectionViewDelegate & UICollectionViewDataSource>(_ source: D) {
    collectionView.dataSource = source
    collectionView.delegate = source
    collectionView.reloadData()
  }
}
