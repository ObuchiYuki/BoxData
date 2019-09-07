//
//  TagFactory.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class TagFactory {
    static func idFromType<T: Tag>(_ type:T.Type) -> UInt8 {
        fatalError()
    }
    static func idFromValue<T: Tag>(_ value:T? = nil) -> UInt8 {
        fatalError()
    }
    static func fromID(id: UInt8) -> Tag {
        switch TagID(rawValue: id)! {
        case .end:      return EndTag()
        case .byte:     return ByteTag(value: nil)
        case .short:    return ShortTag(value: nil)
        case .int:      return IntTag(value: nil)
        case .long:     return LongTag(value: nil)
        case .float:    return FloatTag(value: nil)
        case .double:   return DoubleTag(value: nil)
        case .byteArray:return ByteArrayTag(value: nil)
        case .string:   return StringTag(value: nil)
        case .list:     return ListTag(value: nil)
        case .compound: return CompoundTag(value: nil)
        case .intArray: return IntArrayTag(value: nil)
        case .longArray:return LongArrayTag(value: nil)
        }
    }
    static func fromID<T>(type: T.Type, id:UInt8) -> ValueTag<T> {
        fatalError()
    }
}
