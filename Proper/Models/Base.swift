//
//  Base.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

protocol Base {
    static var namespace: String { get }
    var identifier: String { get }
    
    func topicFor() -> String
    static func topicFor(identifier: String) -> String
}

extension Base {
    func topicFor() -> String {
        return Self.topicFor(self.identifier)
    }
    static func topicFor(identifier: String) -> String {
        return "\(Self.namespace).\(identifier)"
    }
}
