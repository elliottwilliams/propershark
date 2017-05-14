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

/// A data source for a collection view of route badges.
class RoutesCollectionViewModel: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    var routes: AnyProperty<[MutableRoute]>

    init(routes: AnyProperty<Set<MutableRoute>>) {
        self.routes = routes.map { $0.sorted() }
    }

    init(station: MutableStation) {
        self.routes = AnyProperty(initialValue: [], producer: station.routes.producer.map({ $0.sorted() }))
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return routes.value.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) ->
        UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "badgeCell", for: indexPath)
            as! RoutesCollectionViewCell
        let route = routes.value[indexPath.row]

        // Disable animations on the badge for any attributes that are going to be applied synchronously.
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Bind to route attributes.
        cell.disposable += route.color.producer.ignoreNil().startWithNext { cell.badge.color = $0 }
        cell.badge.routeNumber = route.shortName

        CATransaction.commit()
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! RoutesCollectionViewCell?
        cell?.badge.highlighted = true
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! RoutesCollectionViewCell?
        cell?.badge.highlighted = false
    }
}
