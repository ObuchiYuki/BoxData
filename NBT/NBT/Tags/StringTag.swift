//
//  StringTag.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class StringTag: ArrayTag<String> {

    public static let zero = StringTag(value: "")

    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(length)
        
        try dos.write(value!)
    }
    
    override public func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        let length:UInt32 = try dis.uInt32()
        var _value = [Int32]()
        
        for _ in 0..<length {
            _value.append(try dis.readBytes())
        }
        
        self.value = _value
    }
    
    override public func valueString(maxDepth: Int) -> String {
        return value ?? "nil"
    }
}
