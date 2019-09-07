//
//  Tag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//


public class ValueTag<T>: Tag {
    
    public typealias Element = T
    
    // ====================================================== //
    // MARK: - Properties -
    public var value: T!
    
    // ====================================================== //
    // MARK: - Construcotr -
    init(value:T? = nil) {
        self.value = value
    }
    
    override public func valueString(maxDepth: Int) -> String {
        return value.map{"\($0)"} ?? "nil"
    }

    override public func tagString() -> String {
        return valueString(maxDepth: Tag.defaultMaxDepth)
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
