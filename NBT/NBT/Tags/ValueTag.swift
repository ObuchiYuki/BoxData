//
//  Tag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

/**
 This class represents tag with value. Use generics to represent value type.
 All Tag with value must stem from this class.
 
 */
public class ValueTag<T>: Tag {
    
    /// The type of value contained in ValueTag.
    public typealias Element = T
    
    /// The value of tag.
    /// Initirized from `init(value:)` or `deserializeValue(_:,_:)`
    public var value: T!
    
    /// The initirizer of `ValueTag`. You can initirize `ValueTag` value with nil or some
    init(value:T? = nil) {
        self.value = value
    }
    
    /// This method returns the description of `ValueTag`.
    override public func valueString(maxDepth: Int) -> String {
        return value.map{"\($0)"} ?? "nil"
    }
}

/// `ValueTag` with `Equatable` type can be `Equatable`.
extension ValueTag: Equatable where Element: Equatable {
    
    static public func == (left:ValueTag, right:ValueTag) -> Bool {
        return left.value == right.value
    }
}

/// `ValueTag` with `Hashable` type can be `Hashable`.
extension ValueTag: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
