//
//  Tag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//


public class Tag<T>: AnyTag {
    
    public typealias Element = T
    
    // ====================================================== //
    // MARK: - Properties -
    public var value: T!
    
    // ====================================================== //
    // MARK: - Construcotr -
    init(typeID: UInt8, value:T? = nil) {
        super.init(typeID: typeID)
        
        self.value = value
    }
    
    required init(typeID: UInt8) {
        super.init(typeID: typeID)
        
        self.value = nil
    }
    
    override func valueString(maxDepth: Int) -> String {
        return value.map{"\($0)"} ?? "nil"
    }

    override func tagString() -> String {
        valueString(maxDepth: AnyTag.defaultMaxDepth)
    }
}

extension Tag: Equatable where Element: Equatable {
    static public func == (left:Tag, right:Tag) -> Bool {
        return left.value == right.value
    }
}

extension Tag: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
