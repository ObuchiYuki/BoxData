//
//  IntegerTag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class IntegerTag<T: BinaryInteger>: Tag<T> {

    init(value: T) {
        super.init(value: value)
    }
    
    public func asInt8() -> Int8? {
        return value.map{Int8($0)}
    }

    public func asInt16() -> Int16? {
        return value.map{Int16($0)}
    }

    public func asInt32() -> Int32? {
        return value.map{Int32($0)}
    }

    public func asInt64() -> Int64? {
        return value.map{Int64($0)}
    }
    
    public func asFloat() -> Float? {
        return value.map{Float($0)}
    }
    
    public func asDouble() -> Double? {
        return value.map{Double($0)}
    }
}

