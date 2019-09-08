//
//  main.swift
//  BoxData
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

struct Person: Codable {
    let name:String
    let age:Int
    let birth:Country
    
    struct Country: Codable {
        let name:String
        let state:String
    }
}

do {
    let alice = Person(name: "Alice", age: 16, birth: .init(name: "America", state: "Oregon"))
    let encoder = BoxEncoder()
    let data = try encoder.encode(alice)
    
    FileManager.default.createFile(atPath:"/Users/yuki/Desktop/main.tp", contents: data)
    
}catch {
    print(error)
}





/**
 

 
 
 if false {
     let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/yuki/Desktop/main.tp"))
     
     let stream = DataReadStream(data: data)
     
     let tag = try Tag.deserialize(from: stream, maxDepth: 512)
     
     print(tag)
 }else{
     let stream = DataWriteStream()
     
     let component = CompoundTag(value: [
         "people": ListTag(value: [
             CompoundTag(value: [
                 "name": StringTag(value: "Alice"),
                 "age": IntTag(value: 16)
             ]),
             CompoundTag(value: [
                 "name": StringTag(value: "Bob"),
                 "age": IntTag(value: 22)
             ]),
             CompoundTag(value: [
                 "name": StringTag(value: "Catherine"),
                 "age": IntTag(value: 19)
             ])
         ])
     ])
     
     try component.serialize(into: stream ,maxDepth: 512)
     
     FileManager.default.createFile(atPath:"/Users/yuki/Desktop/main.tp", contents: stream.data)
     
 }
 */
