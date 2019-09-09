//
//  main.swift
//  BoxData
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

struct Region: Codable {
    let blocks =
        Array(repeating: Array.init(repeating: Array.init(repeating: Section(), count: 32), count: 10), count: 32)
}
struct Section: Codable {
    let anchor: UInt16 = 0
    let fill: UInt16 = 0
    let fillAnchor: UInt16 = 0
    let data: UInt8 = 0
}

do {
    let region = Region()
    
    let encoder = BoxEncoder()
    let decoder = BoxDecoder()
    
    let data = try encoder.encode(region)
        
    FileManager.default.createFile(atPath:"/Users/yuki/Desktop/region.box", contents: data)
    
    
    let decoded = try decoder.decode(Region.self, from: data)
    
    print(decoded)
    
    
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
