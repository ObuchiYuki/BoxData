//
//  TagFactory.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class TagFactory {
    static func idFromType<T: Tag>(_ type:T.Type) -> TagID {
        if T.self == EndTag.self         {return .end}
        if T.self == ByteTag.self        {return .byte}
        if T.self == ShortTag.self       {return .short}
        if T.self == IntTag.self         {return .int}
        if T.self == LongTag.self        {return .long}
        if T.self == FloatTag.self       {return .float}
        if T.self == DoubleTag.self      {return .double}
        if T.self == ByteArrayTag.self   {return .byteArray}
        if T.self == StringTag.self      {return .string}
        if T.self == ListTag.self        {return .list}
        if T.self == CompoundTag.self    {return .compound}
        if T.self == IntArrayTag.self    {return .intArray}
        if T.self == LongArrayTag.self   {return .longArray}
        
        fatalError("Not matching tag")
    }
    
    static func idFromValue<T: Tag>(_ value:T? = nil) -> TagID {
        return idFromType(T.self)
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
}
