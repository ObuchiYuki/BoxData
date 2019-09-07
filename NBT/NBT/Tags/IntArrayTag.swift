//
//  IntArrayTag.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class IntArrayTag: ArrayTag<[Int32]> {

    public static let zero = IntArrayTag(value: [])
    
    init(value:[Int32]) {
        super.init(typeID: TagID.intArray.rawValue, value: value)
    }
    
    required init(typeID: UInt8) {fatalError()}

    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(length)
        
        try value?.forEach{try dos.write($0) }
    }
    
    override public func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        let length:Int32 = try dis.readBytes()
        var _value = [Int32]()
        
        for _ in 0..<length {
            _value.append(try dis.readBytes())
        }
        self.value = _value
    }
    
    override public func valueString(maxDepth: Int) -> String {
        value.map{"\($0)s"} ?? "nil"
    }
}
