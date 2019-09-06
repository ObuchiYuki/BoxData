//
//  ListTag.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class ListTag<U, T: Tag<U>>: Tag<[T]> {
    
    public var size:Int32 {
        return Int32(value!.count)
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
        try dos.write(TagFactory.idFromType(T.self))
        try dos.write(size)
        
        if size != 0 {
            for element in value {
                try element.serialize(into: dos, maxDepth: decrementMaxDepth(maxDepth))
            }
        }
    }
    
    override public func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        let typeId = try dis.uInt8()
        
        let size = try dis.uInt32()
        
        
        if (size != 0) {
            for i in 0..<size {
                let t = T(value: nil)
                t.deserializeValue(into: dis, maxDepth: decrementMaxDepth(maxDepth))
                append(t)
            }
        }
    }
    
    override public func valueString(maxDepth: Int) -> String {
        value.map{"\($0)"} ?? "nil"
    }
}
