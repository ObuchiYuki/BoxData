//
//  main.swift
//  BoxData
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

struct Person: Codable {
    let age:UInt8
    let name:String
    
    let birth:Country
    
    struct Country:Codable {
        let name:String
        let id:UInt16
    }
}

do {

    let alice = Person(age: 16, name: "Alice", birth: .init(name: "America", id: 12))
    let bob = Person(age: 22, name: "Bob", birth: .init(name: "America", id: 12))
    let people = Array(repeating: alice, count: 10000) + Array(repeating: bob, count: 10000)
    
    let encoder = BoxEncoder()
    
    // ================================================== //
    let start = Date()
    
    let data = try encoder.encode(people)
    
    FileManager.default.createFile(atPath:"/Users/yuki/Desktop/main.box2", contents: data)
    
    print(Date().timeIntervalSince(start))
    // box      0.192      100KB
    // box2     0.177      700B
    // box3     0.2        29 KB
    // json     0.258      1.2MB
    // plist    0.33       60KB
    // ================================================== //
}catch {
    print(error)
}



/**
 
 let alice_ = try decoder.decode(Person.self, from: data)
 
 print(alice_)
 
 
 FileManager.default.createFile(atPath:"/Users/yuki/Desktop/main.tp", contents: data)
 
 
 
 
 
 
 
 let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/yuki/Desktop/main.tp"))
 
 let stream = DataReadStream(data: data)
 
 let tag = try Tag.deserialize(from: stream, maxDepth: 512)
 
 print(tag)
 
 
 let alice = Person(age: nil)
 let encoder = BoxEncoder()
 let data = try encoder.encode(alice)
 
 FileManager.default.createFile(atPath:"/Users/yuki/Desktop/main.tp", contents: data)
 
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
