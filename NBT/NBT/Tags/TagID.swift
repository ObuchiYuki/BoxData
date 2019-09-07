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
    case byte           = 1
    case short          = 2
    case int            = 3
    case long           = 4
    case float          = 5
    case double         = 6
    case byteArray      = 7
    case string         = 8
    case list           = 9
    case compound       = 10
    case intArray       = 11
    case longArray      = 12
}
