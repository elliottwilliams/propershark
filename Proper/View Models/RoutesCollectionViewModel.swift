//
//  RoutesCollectionViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 9/23/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Dwifft

class RoutesCollectionViewModel: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    var routes: AnyProperty<[MutableRoute]>

    init(routes: AnyProperty<Set<MutableRoute>>) {
        self.routes = routes.map { $0.sort() }
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return routes.value.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BadgeCell", forIndexPath: indexPath) as! RoutesCollectionViewCell
        let route = routes.value[indexPath.row]

        // Bind to route attributes.
        cell.disposable += route.color.producer.startWithNext { color in
            _ = color.flatMap { cell.badge.color = $0 }
        }
        cell.badge.routeNumber = route.shortName

        return cell
    }
}
