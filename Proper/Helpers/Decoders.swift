//
//  Decoders.swift
//  Proper
//
//  Created by Elliott Williams on 7/4/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo

extension UIColor: Decodable {
    public static func decode(json: JSON) -> Decoded<UIColor> {
        switch json {
        case .String(var hexString):
            if hexString.hasPrefix("#") {
                hexString.removeAtIndex(hexString.characters.startIndex)
            }
            guard let hex = Int.init(hexString, radix: 16)
                else { return .Failure(.Custom("\(hexString) not a hexadecimal integer")) }
            return .Success(UIColor(
                red:   CGFloat(hex & 0xFF0000 >> 16)/255.0,
                green: CGFloat(hex & 0x00ff00 >> 8 )/255.0,
                blue:  CGFloat(hex & 0x0000ff >> 0 )/255.0,
                alpha: 1.0
                ))
        case .Array(let rgbArray):
            guard rgbArray.count == 3 || rgbArray.count == 4,
                case .Number(let r) = rgbArray[0],
                case .Number(let g) = rgbArray[1],
                case .Number(let b) = rgbArray[2]
                else { return .Failure(.Custom("expected a 3 item RGB array or a 4 item RGBA array containing floats")) }
            var a = NSNumber()
            if let aj = rgbArray[safe: 4] {
                if case .Number(a) = aj { }
                else { a = 1.0 }
            }
            return .Success(UIColor(
                red: CGFloat(r),
                green: CGFloat(g),
                blue: CGFloat(b),
                alpha: CGFloat(a)
                ))
        default:
            return .Failure(.TypeMismatch(expected: "string or array", actual: "something else"))
        }
    }
}