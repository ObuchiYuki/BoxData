//
//  Tag.swift
//  NBT
//
//  Created by yuki on 2019/09/07.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class Tag {
    
    func tagID() -> TagID {
        fatalError("Subclass of Tag must implement tagID().")
    }
    
    // ====================================================== //
    // MARK: - Methods -
    
    /// 無名Data書き込み
    public func serialize(into dos:DataWriteStream, maxDepth:Int) throws {
        
        try serialize(into: dos, named: "", maxDepth: maxDepth)
    }

    /// 有名Data書き込み
    public func serialize(into dos:DataWriteStream, named name:String, maxDepth: Int) throws {
        let a = tagID().rawValue
        
        try dos.write(a) // まずタグを書き込み
        
        if (tagID() != .end) { // TAG_ENDでなければ書き込み
            try dos.write(name)
        }
        
        try serializeValue(into: dos, maxDepth: maxDepth)
    }

    /// 読み込み
    public static func deserialize(from dis: DataReadStream, maxDepth:Int) throws -> Tag {
        let id = try dis.uInt8()
        let tag = TagFactory.fromID(id: id)
        
        if (id != 0) {
            try tag.deserializeValue(from: dis, maxDepth: maxDepth);
        }
        
        return tag
    }
    
    public func decrementMaxDepth(_ maxDepth: Int) -> Int {
        assert(maxDepth > 0, "negative maximum depth is not allowed")
        assert(maxDepth != 0, "reached maximum depth of NBT structure")
        
        return maxDepth - 1
    }
    // =========================== //
    // MARK: - Overridable -
    
    open func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        fatalError()
    }
    
    open func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        fatalError()
    }
    
    open func valueString(maxDepth: Int) -> String {
        fatalError()
    }

    open func tagString() -> String {
        fatalError()
    }
}

extension Tag {
    public static var defaultMaxDepth:Int {
        return 512
    }
}

extension Tag: CustomStringConvertible {
    public var description: String {
        return tagString()
    }
}
