//
//  Tag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//


public class Tag<T: Hashable> {
         
    // ====================================================== //
    // MARK: - Properties -
    public var value: T?
    
    public var id:UInt8 {
        return TagFactory.idFromClass(self)
    }

    // ====================================================== //
    // MARK: - Construcotr -
    init(value:T?) {
        self.value = value
    }

    // ====================================================== //
    // MARK: - Methods -
    
    /// 無名Data書き込み
    public func serialize(into dos:DataWriteStream, maxDepth:Int) throws {
        try serialize(into: dos, named: "", maxDepth: maxDepth)
    }

    /// 有名Data書き込み
    public func serialize(into dos:DataWriteStream, named name:String, maxDepth: Int) throws {
        try dos.write(id) // まずタグを書き込み
        
        if (id != 0) { // TAG_ENDでなければ書き込み
            try dos.write(name)
        }
        
        try serializeValue(into: dos, maxDepth: maxDepth)
    }

    /// 読み込み
    public static func deserialize<U>(from dis: DataReadStream, maxDepth:Int) throws -> Tag<U> {
        let id = try dis.uInt8()
    
        let tag:Tag<U> = TagFactory.fromID(id)
        
        if (id != 0) {
            //dis.string(count: T##Int##);
            try tag.deserializeValue(into: dis, maxDepth: maxDepth);
        }
        
        return tag
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
        return value.map{"\($0)"} ?? "nil"
    }

    open func tagString() -> String {
        valueString(maxDepth: Tag.defaultMaxDepth)
    }
    
    // =========================== //
    // MARK: - Private -
    private func decrementMaxDepth(maxDepth: Int) -> Int {
        assert(maxDepth > 0, "negative maximum depth is not allowed")
        assert(maxDepth == 0, "reached maximum depth of NBT structure")
        
        return maxDepth - 1
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

extension Tag: Equatable {
    static public func == (left:Tag, right:Tag) -> Bool {
        return type(of: left) == type(of: right)
    }
}

extension Tag: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
