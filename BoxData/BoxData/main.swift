//
//  main.swift
//  BoxData
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

struct Person:Codable {
    let name:String
    let age:UInt32
}
    

do {
    let start = Date()
    let alice = Array(repeating: Person(name: "Alice", age: UInt32.random(in: 0...UInt32.max)), count: 100000)
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let data = try encoder.encode(alice)
        
    FileManager.default.createFile(atPath:"/Users/yuki/Desktop/region.json", contents: data)
    
    
    let decoded = try decoder.decode(Array<Person>.self, from: data)
    
    print(Date().timeIntervalSince(start), "s")
    
    print(decoded[0])
    
    // speed   0.057    84  KB
    // size    0.071    183 B
    
    
    
    // Type    Time     File Size
    //
    // plist   2.07     5.4 MB
    // box2    2.28     145 B
    // json    2.91     6.1 MB

}catch {
    print(error)
}

// Encode   Time        File size
//
// box      0.177       800B
// plist    0.192       640KB
// json     0.251       1.2MB

// Decode   Time
//
// json     0.307
// box      0.302
// plist    0.247




/**
 

 // ================================================== //
 
 //
 
 
 
 let person = Array.init(repeating: alice, count: 100000)
 let encoder = BoxEncoder()
 
 let data = try encoder.encode(person)
 
 FileManager.default.createFile(atPath:"/Users/yuki/Desktop/person.box2", contents: data)
 
 // Decode
 // box      0.282
 // plist    0.26
 // json     0.227
 
 print(decoded[0])
 
 
 
 
 let alice_ = try decoder.decode(Person.self, from: data)
 
 print(alice_)
 
 
 FileManager.default.createFile(atPath:"/Users/yuki/Desktop/main.tp", contents: data)
 
 
 
 
 
 
 
 
 
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
