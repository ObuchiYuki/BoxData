//
//  main.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

print("Hello, World!")




let nbt = CompoundTag(value: [
    "name": StringTag(value: "Hi"),
    "position": ShortTag(value: 12)
])
    
    ListTag(value: [
    IntTag(value: 12),
    IntTag(value: 12),
    IntTag(value: 12),
    IntTag(value: 12)
])

    
print(nbt)
