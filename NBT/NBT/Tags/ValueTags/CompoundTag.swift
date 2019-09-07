//
//  CompoundTag.swift
//  NBT
//
//  Created by yuki on 2019/09/07.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class CompoundTag: ValueTag<[String: Tag]> {
    
    override func tagID() -> TagID { .compound }

    public var size:UInt32 {
        return value.map{UInt32($0.count)} ?? 0
    }
        
    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws { 
        for (key, value) in value {
            
            try value.serialize(into: dos, named: key, maxDepth: decrementMaxDepth(maxDepth))
        }
        
        try EndTag.shared.serialize(into: dos, maxDepth: maxDepth)
    }
    
    override public func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        self.value = [:]
        
        var id = try dis.uInt8()
        var name = try dis.string()
        
        while true {
            let tag = TagFactory.fromID(id: id)
            try tag.deserializeValue(from: dis, maxDepth: decrementMaxDepth(maxDepth))
            
            value[name] = tag
            
            id = try dis.uInt8()
            if id == 0 {break}
            name = try dis.string()
        }
    }
}
