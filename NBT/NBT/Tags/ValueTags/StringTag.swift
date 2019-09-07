//
//  StringTag.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class StringTag: ArrayTag<String> {
    
    override func tagID() -> TagID { .string }
    
    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(UInt8(length))
        
        try dos.write(value!)
    }
    
    override public func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        let length = try dis.uInt8()
        var _value = [UInt8]()
        
        for _ in 0..<length {
            _value.append(try dis.uInt8())
        }
        
        self.value = String(bytes: _value, encoding: .utf8)
    }
    
    override public func valueString(maxDepth: Int) -> String {
        return value ?? "nil"
    }
}
