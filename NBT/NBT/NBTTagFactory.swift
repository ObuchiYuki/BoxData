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
    static func fromID(id: UInt8) -> AnyTag {
        fatalError()
    }
    static func fromID<T>(type: T.Type, id:UInt8) -> ValueTag<T> {
        fatalError()
    }
}
