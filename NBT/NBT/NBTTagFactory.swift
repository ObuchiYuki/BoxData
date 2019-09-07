//
//  TagFactory.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class TagFactory {
    static func idFromType<U, T: ValueTag<U>>(_ type:T.Type) -> UInt8 {
        fatalError()
    }
    static func idFromValue<U, T: ValueTag<U>>(_ value:T? = nil) -> UInt8 {
        fatalError()
    }
    static func fromID(id: UInt8) -> Tag {
        switch TagID(rawValue: id)! {
        case .end:      return EndTag(value: nil)
        case .byte:     return ByteTag(value: nil)
        case .short:    return ShortTag(value: nil)
        case .int:      return IntTag(value: nil)
        case .long:     return LongTags(value: nil)
        case .float:    return FloatTag(value: nil)
        case .double:   return DoubleTag(value: nil)
        case .byteArray:
            return ByteArrayTag
        case .string:
            return StringTag
        case .list:
            return ListTag
        case .compound:
            return CompoundTag
        case .intArray:
            return IntArrayTag
        case .longArray:
            return LongArrayTag
            
            
            
        case .byte:
            <#code#>
        default:
            <#code#>
        }
    }
    static func fromID<T>(type: T.Type, id:UInt8) -> ValueTag<T> {
        fatalError()
    }
}
