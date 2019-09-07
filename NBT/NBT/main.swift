//
//  main.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

print("Hello, World!")

let player = CompoundTag(value: [
    "DataVersion": ShortTag(value: 12),
    "Demention": ShortTag(value: 12),
    "foodLevel": IntTag(value: 1212)
])


print(player)
