//
//  Tag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//


public class ValueTag<T>: Tag {
    
    public typealias Element = T
    
    public var value: T!
    
    init(value:T? = nil) {
        self.value = value
    }
    
    /// Value String
    override public func valueString(maxDepth: Int) -> String {
        return value.map{"\($0)"} ?? "nil"
    }
}

extension ValueTag: Equatable where Element: Equatable {
    static public func == (left:ValueTag, right:ValueTag) -> Bool {
        return left.value == right.value
    }
}

extension ValueTag: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
