//
//  ListTag.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class ListTag<T: Tag>: ValueTag<[T]> {
    
    override func tagID() -> TagID { .list }
        
    public var size:UInt32 {
        return UInt32(value!.count)
    }

    public func remove(index:Int) -> T? {
        return value?.remove(at: index)
    }
    public func clear() {
        value = []
    }
    
    public func append(_ t:T) {
        self.value.append(t)
    }
    
    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(size)
        
        if size != 0 {
            for element in value {
                try element.serialize(into: dos, maxDepth: decrementMaxDepth(maxDepth))
            }
        }
    }
    
    override public func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        self.value = []
        
        let size = try dis.uInt32()
        
        print(size)
        
        if (size != 0) {
            for _ in 0..<size {
                let typeId = try dis.uInt8()
                let t = TagFactory.fromID(id: typeId)
                
                print(type(of: t), typeId)
                
                try t.deserializeValue(from: dis, maxDepth: decrementMaxDepth(maxDepth))
                
                self.append(t as! T)
            }
        }
    }
    
    override public func valueString(maxDepth: Int) -> String {
        return value.map{"\($0)"} ?? "nil"
    }
}
