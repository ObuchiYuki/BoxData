//
//  ByteArrayTag.swift
//  NBT
//
//  Created by yuki on 2019/09/07.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class ByteArrayTag: ArrayTag<[Int8]> {

    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(length)
        
        try value?.forEach{try dos.write($0) }
    }
    
    override public func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        let length:Int32 = try dis.readBytes()
        var _value = [Int8]()
        
        for _ in 0..<length {
            _value.append(try dis.readBytes())
        }
        self.value = _value
    }
    
    override public func valueString(maxDepth: Int) -> String {
        return value.map{"\($0)s"} ?? "nil"
    }
}
