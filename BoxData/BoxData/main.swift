//
//  main.swift
//  BoxData
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

do {
    
    if true {
        let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/yuki/Desktop/main.tp"))
        
        let stream = DataReadStream(data: data)
        
        let tag = try Tag.deserialize(from: stream, maxDepth: 512)
        
        print(tag)
    }else{
        let stream = DataWriteStream()
        
        let component = CompoundTag(value: [
            "ages": ListTag(value: [
                IntTag(value: 12),
                IntTag(value: 12),
                CompoundTag(value: [
                    "name": StringTag(value: "Alice"),
                    "age": IntTag(value: 12),
                    "list": ListTag(value: [])
                ]),
                IntTag(value: 12),
                IntTag(value: 12),
                IntTag(value: 12),
                IntTag(value: 12),
            ])
        ])
        
        try component.serialize(into: stream ,maxDepth: 512)
        
        FileManager.default.createFile(atPath:"/Users/yuki/Desktop/main.tp", contents: stream.data)
        
    }
    
}catch {
    print(error)
}
