//
//  NotificationBar.swift
//  Proper
//
//  Created by Elliott Williams on 10/15/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import UIKit

/// A text-based toast notification.
class NotificationBar: UIView {
  lazy var title: UILabel = {
    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.textAlignment = .center
    title.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
    title.textColor = UIColor.white
    return title
  }()

  var showsNotification = false {
    didSet { updateVisibilityConstraints() }
  }

  private let verticalPadding = CGFloat(8)
  private lazy var heightConstraint: NSLayoutConstraint = {
    return self.heightAnchor.constraint(equalToConstant: 0)
  }()

  override var intrinsicContentSize: CGSize {
    return CGSize(width: title.intrinsicContentSize.width, height: title.intrinsicContentSize.height + verticalPadding*2)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = UIColor.darkGray
    translatesAutoresizingMaskIntoConstraints = false

    addSubview(title)
    installConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func installConstraints() {
    NSLayoutConstraint.activate([
      title.centerXAnchor.constraint(equalTo: centerXAnchor),
      title.centerYAnchor.constraint(equalTo: centerYAnchor),
      heightConstraint,
      ])
  }

  private func updateVisibilityConstraints() {
    heightConstraint.constant = showsNotification ? intrinsicContentSize.height : 0
  }
}
