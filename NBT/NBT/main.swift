//
//  main.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

print("Hello, World!")

do {
    let stream = DataWriteStream()
    
    let alice = CompoundTag(value: [
        "name": StringTag(value: "Alice"),
        "age": IntTag(value: 12),
    ])
    
    try alice.serializeValue(into: stream, maxDepth: 512)
    
    FileManager.default.createFile(atPath: "/Users/yuki/Desktop/main.tp", contents: stream.data)    
    
}catch {
    print(error)
}

