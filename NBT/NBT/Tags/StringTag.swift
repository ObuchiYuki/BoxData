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

    init(value:String) {
        super.init(typeID: TagID.string.rawValue, value: value)
    }
    
    required init(typeID: UInt8) {fatalError()}
    
    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(length)
        
        try dos.write(value!)
    }
    
    override public func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        let length:UInt32 = try dis.uInt32()
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
