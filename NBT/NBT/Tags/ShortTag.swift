//
//  ShortTag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation


public class ShortTag: IntegerTag<Int16> {

    public static let zero = ShortTag(value: 0)

    init(value: Int16) {
        super.init(typeID: TagID.short.rawValue, value: value)
    }
    required init(typeID: UInt8) { fatalError("init(typeID:) has not been implemented") }
    
    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try value.map{ try dos.write($0) }
    }
    
    override public func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        self.value = try dis.readBytes()
    }
    
    override public func valueString(maxDepth: Int) -> String {
        value.map{"\($0)"} ?? "nil"
    }
}
