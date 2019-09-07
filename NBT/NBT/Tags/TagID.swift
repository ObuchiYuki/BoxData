//
//  TagID.swift
//  NBT
//
//  Created by yuki on 2019/09/07.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

enum TagID: UInt8 {
    case end            = 0
    case byte
    case short
    case int
    case long
    case float
    case double
    case byteArray
    case string
    case list
    case compound
    case intArray
    case longArray
}
