//
//  Pipe.swift
//  Proper
//
//  Created by Elliott Williams on 12/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

infix operator |> { associativity left }
infix operator <| { associativity left }

func |> <A, B> (v: A, fn: A -> B) -> B {
    return fn(v)
}

func <| <A, B> (fn: A -> B, v: A) -> B {
    return fn(v)
}
