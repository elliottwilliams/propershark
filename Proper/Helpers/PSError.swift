//
//  PSError.swift
//  Proper
//
//  Created by Elliott Williams on 6/30/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit

class PSError: NSError {
    static let domain = "ProperShark"
    
    init(code: PSErrorCode, userInfo: [NSObject: AnyObject]? = nil) {
        var info = userInfo ?? [:]
        info[NSLocalizedDescriptionKey] = code.description()
        
        super.init(domain: PSError.domain, code: code.rawValue, userInfo: info)
    }
    
    init(error: NSError, code: PSErrorCode) {
        var info = error.userInfo
        info[NSLocalizedDescriptionKey] = code.description()
        super.init(domain: error.domain, code: error.code, userInfo: info)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum PSErrorCode: Int {
    case entityLoadFailure
    case mdwampError
    
    func description() -> String {
        switch(self) {
        case .entityLoadFailure:
            return "Unable to load information about the system from our servers."
        case .mdwampError:
            return "We lost the connection to our servers."
        }
    }
}
