//
//  Tag.swift
//  NBT
//
//  Created by yuki on 2019/09/07.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

/**
 Represents non value type Tag. If use want to use tag with value use ValueTag instead.
 
 Tag serialization
 
 ### for Normal tag
 |tag_id|name|value|
 
 ### for End tag
 |tag_id|
 
 */
public class Tag {
    
    /// Subclass of Tag must implement tagID() to return own type.
    func tagID() -> TagID {
        fatalError("Subclass of Tag must implement tagID().")
    }
    
    // MARK: - Methods -
    
    /// serialize data with no name.
    /// for list, array or root tag.
    public func serialize(into dos:DataWriteStream, maxDepth:Int) throws {
        
        try serialize(into: dos, named: "", maxDepth: maxDepth)
    }
 
    /// serialize data with name. for component
    public func serialize(into dos:DataWriteStream, named name:String, maxDepth: Int) throws {
        let id = tagID()
        
        try dos.write(id.rawValue)
        
        if (id != .end) {
            try dos.write(name)
        }
        
        try serializeValue(into: dos, maxDepth: maxDepth)
    }

    /// deserialize input.
    public static func deserialize(from dis: DataReadStream, maxDepth:Int) throws -> Tag {
        let id = try dis.uInt8()
        let tag = TagFactory.fromID(id: id)
        
        if (id != 0) {
            try tag.deserializeValue(from: dis, maxDepth: maxDepth);
        }
        
        return tag
    }
    
    /// decrement maxDepth use this method to decrease maxDepth.
    /// This method check if maxDepth match requirement.
    public func decrementMaxDepth(_ maxDepth: Int) -> Int {
        assert(maxDepth > 0, "negative maximum depth is not allowed")
        assert(maxDepth != 0, "reached maximum depth of NBT structure")
        
        return maxDepth - 1
    }
    
    
    // MARK: - Overridable Methods
    // Subclass of Tag must override those methods below to implement function.
    
    /// Subclass of Tag must override this method to serialize value.
    open func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        fatalError("Subclass of Tag must implement serializeValue(into:, _:).")
    }
    
    /// Subclass of Tag must override this method to deserialize value.
    open func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        fatalError("Subclass of Tag must implement deserializeValue(from:, _:).")
    }
    
    /// Subclass of Tag must override this method to retuen description of Value.
    open func valueString(maxDepth: Int) -> String {
        fatalError("Subclass of Tag must implement valueString(maxDepth:)")
    }
}

extension Tag {
     
    /// defalt max depth of deserialize.
    static let defaultMaxTag = 512
}

extension Tag: CustomStringConvertible {
    
    public var description: String {
        return valueString(maxDepth: Tag.defaultMaxTag)
    }
}
