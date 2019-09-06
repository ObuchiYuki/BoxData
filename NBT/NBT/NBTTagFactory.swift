//
//  TagFactory.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class TagFactory {
    static func idFromClass<U:Hashable, T: Tag<U>>() -> UInt8 {
        fatalError()
    }
    static func idFromClass<U:Hashable, T: Tag<U>>(_ value:T? = nil) -> UInt8 {
        fatalError()
    }
    static func fromID<T: Hashable>(_ id:UInt8) -> Tag<T> {
        fatalError()
    }
}
