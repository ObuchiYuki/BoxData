//
//  AnyTag.swift
//  NBT
//
//  Created by yuki on 2019/09/07.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class AnyTag {
    public var typeID:UInt8
    
    required init(typeID: UInt8) {
        self.typeID = typeID
    }
    
    // ====================================================== //
    // MARK: - Methods -
    
    /// 無名Data書き込み
    public func serialize(into dos:DataWriteStream, maxDepth:Int) throws {
        try serialize(into: dos, named: "", maxDepth: maxDepth)
    }

    /// 有名Data書き込み
    public func serialize(into dos:DataWriteStream, named name:String, maxDepth: Int) throws {
        try dos.write(typeID) // まずタグを書き込み
        
        if (typeID != 0) { // TAG_ENDでなければ書き込み
            try dos.write(name)
        }
        
        try serializeValue(into: dos, maxDepth: maxDepth)
    }

    /// 読み込み
    public static func deserialize<U>(from dis: DataReadStream, maxDepth:Int) throws -> ValueTag<U> {
        let id = try dis.uInt8()
    
        let tag = TagFactory.fromID(type: U.self, id: id)
        
        if (id != 0) {
            try tag.deserializeValue(into: dis, maxDepth: maxDepth);
        }
        
        return tag
    }
    
    public func decrementMaxDepth(_ maxDepth: Int) -> Int {
        assert(maxDepth > 0, "negative maximum depth is not allowed")
        assert(maxDepth == 0, "reached maximum depth of NBT structure")
        
        return maxDepth - 1
    }
    // =========================== //
    // MARK: - Overridable -
    
    open func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        fatalError()
    }
    
    open func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        fatalError()
    }
    
    open func valueString(maxDepth: Int) -> String {
        fatalError()
    }

    open func tagString() -> String {
        fatalError()
    }
}

extension AnyTag {
    public static var defaultMaxDepth:Int {
        return 512
    }
}

extension AnyTag: CustomStringConvertible {
    public var description: String {
        return tagString()
    }
}
