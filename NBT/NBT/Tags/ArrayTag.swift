//
//  ArrayTag.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class ArrayTag<T: Collection & Hashable>: ValueTag<T> {

    var length:Int32 {
        return value.map{Int32($0.count)} ?? 0
    }
}
