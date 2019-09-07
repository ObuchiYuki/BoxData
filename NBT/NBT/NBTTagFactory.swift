//
//  TagFactory.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class TagFactory {
    static func idFromType<U, T: Tag<U>>(_ type:T.Type) -> UInt8 {
        fatalError()
    }
    static func idFromValue<U, T: Tag<U>>(_ value:T? = nil) -> UInt8 {
        fatalError()
    }
    static func fromID<T>(type: T.Type, id:UInt8) -> Tag<T> {
        fatalError()
    }
}
