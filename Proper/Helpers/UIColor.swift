//
//  UIColor.swift
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
        case .String(let hexString):
            return pure(UIColor(hex: hexString))
        case .Array(let rgbArray):
            // Get RGB parameters.
            guard rgbArray.count == 3 || rgbArray.count == 4,
            var r = Double.decode(rgbArray[0]).value,
            var g = Double.decode(rgbArray[1]).value,
            var b = Double.decode(rgbArray[2]).value
            else {
                return .Failure(.Custom("expected a 3 item RGB array or a 4 item RGBA array containing floats"))
            }

            var a = Double.decode(rgbArray[safe: 3] ?? .Number(1)).value!

            // If css-style parameters out of 255 were passed, reduce to a 1.0 scale.
            if max(r, g, b) > 1 {
                (r, g, b) = (r/255, g/255, b/255)
            }
            if a > 1 {
                a = a/255
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