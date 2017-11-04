//
//  NotificationViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/15/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

typealias NotificationObserver = Observer<String?, NoError>
typealias NotificationSignal = Signal<String?, NoError>

class ToastNotificationViewController: UIViewController {
  static let (sharedSignal, sharedObserver) = Signal<String?, NoError>.pipe()

  lazy var notificationBar: NotificationBar = {
    let view = NotificationBar()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  override var navigationItem: UINavigationItem {
    return contentViewController?.navigationItem ?? super.navigationItem
  }

  private var contentViewController: UIViewController? = nil
  private let disposable = ScopedDisposable(CompositeDisposable())

  /// - parameter contentViewController: controller wrapped by this controller
  /// - parameter notificationSignal: non-nil values are displayed as notifications by this controller. The default
  /// value is a signal shared by all ToastNotificationViewControllers
  init(contentViewController: UIViewController?, notificationSignal: NotificationSignal = ToastNotificationViewController.sharedSignal) {
    self.contentViewController = contentViewController
    super.init(nibName: nil, bundle: nil)
    observeNotifications(from: notificationSignal)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    view.addSubview(notificationBar)
    installConstraints()
  }

  override func didMove(toParentViewController parent: UIViewController?) {
    if let contentViewController = contentViewController {
      embedContentViewController(contentViewController)
    }
  }

  func embedContentViewController(_ content: UIViewController) {
    if let oldContent = contentViewController {
      oldContent.willMove(toParentViewController: nil)
      oldContent.view.removeFromSuperview()
      oldContent.removeFromParentViewController()
    }

    contentViewController = content
    addChildViewController(content)
    view.addSubview(content.view)
    NSLayoutConstraint.activate([
      content.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      content.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      content.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      content.view.topAnchor.constraint(equalTo: view.topAnchor),
    ])
    content.didMove(toParentViewController: content)
  }

  private func installConstraints() {
    NSLayoutConstraint.activate([
      notificationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      notificationBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      notificationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
    ])
  }

  private func observeNotifications(from signal: Signal<String?, NoError>) {
    disposable += signal.observe(on: UIScheduler()).observeValues { [weak self] title in
      if let title = title {
        self?.showNotification(title)
      } else {
        self?.hideNotification()
      }
    }
  }
}

// MARK: - Notification API
extension ToastNotificationViewController {
  func showNotification(_ text: String) {
    guard !notificationBar.showsNotification else {
      return
    }
    
    notificationBar.title.text = text
    if !notificationBar.showsNotification {
      UIView.animate(withDuration: 0.25) {
        self.notificationBar.showsNotification = true
        self.view.bringSubview(toFront: self.notificationBar)
        self.view.layoutIfNeeded()
      }
    }
  }

  func hideNotification() {
    guard notificationBar.showsNotification else {
      return
    }
    UIView.animate(withDuration: 0.25) {
      self.notificationBar.showsNotification = false
      self.view.layoutIfNeeded()
    }
  }
}
