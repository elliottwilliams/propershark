//
//  PSError.swift
//  Proper
//
//  Created by Elliott Williams on 6/30/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit

class PSError: NSError {
    let errorCode: PSErrorCode
    let associated: Any?
    
    static let domain = "ProperShark"
    lazy var alert: UIAlertController = self.makeAlert()
    
    init(code: PSErrorCode, associated: Any? = nil, userInfo: [NSObject: AnyObject]? = nil) {
        var info = userInfo ?? [:]
        info[NSLocalizedDescriptionKey] = code.message
        self.errorCode = code
        self.associated = associated
        super.init(domain: PSError.domain, code: code.rawValue, userInfo: info)
    }
    
    /// Create a PSError out of an underlying NSError by giving the error a PSErrorCode
    init(error: NSError, code: PSErrorCode, associated: Any? = nil) {
        var info = error.userInfo
        info[NSLocalizedDescriptionKey] = code.message
        info[NSUnderlyingErrorKey] = error
        self.errorCode = code
        self.associated = associated
        super.init(domain: error.domain, code: error.code, userInfo: info)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeAlert () -> UIAlertController {
        let alert = UIAlertController(title: self.errorCode.title,
                                      message: self.errorCode.message,
                                      preferredStyle: .Alert)
        #if DEBUG
        if let reason = (self.userInfo[NSUnderlyingErrorKey] as? NSError)?.localizedDescription {
            alert.message = [self.errorCode.message, reason].joinWithSeparator("\n")
        }
        #endif
        
        if let associated = self.associated {
            alert.message = [alert.message!, String(associated)].joinWithSeparator("\n")
        }
        
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        return alert
    }
}

// MARK: Defined Error Codes

enum PSErrorCode: Int {
    case mdwampError
    case connectionLost
    case maxConnectionFailures
    case parseFailure
    case decodeFailure
    case mutableModelFailedApply
    case unhandledTopic
    case timeout
    
    var title: String { return self.description().title }
    var message: String { return self.description().message }

    static let genericTitle = "Something went wrong"
    
    private func description() -> (title: String, message: String) {
        switch(self) {
        case .mdwampError:
            return ("Server connection failed", "Our server sent us an error message. Check that your Internet connection is functioning and try again.")
        case .connectionLost:
            return ("Poor connection", "We lost the connection to our server.")
        case .timeout:
            return ("Poor connection", "We were unable to reach \(Config.app.name) servers. Check that your Internet connection is functioning and try again.")
        case .maxConnectionFailures:
            return ("Server connection failed", "We were unable to establish a connection with \(Config.app.name) servers. Check that your Internet connection is functioning and try again.")
        case .parseFailure, .decodeFailure, .mutableModelFailedApply, .unhandledTopic:
            return (PSErrorCode.genericTitle, "Our server sent us some information that could not be understood.")
        }
    }
}
