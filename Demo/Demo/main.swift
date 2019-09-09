//
//  main.swift
//  Demo
//
//  Created by yuki on 2019/09/09.
//  Copyright © 2019 yuki. All rights reserved.
//

import Box

// MARK: - Codable data
struct Person: Codable {
    let name:String
    let age:UInt8
    
    let birth: Country
    
    struct Country: Codable {
        let name:String
        let id:UInt8
    }
}

// MARK: - Sample data
let alice = Person(name: "Alice", age: 16, birth: .init(name: "UK", id: 12))
let bob = Person(name: "Bob", age: 22, birth: .init(name: "America", id: 14))

let people = Array(repeating: alice, count: 5000) + Array(repeating: bob, count: 5000)

// MARK: - Coders
let encoder = BoxEncoder()
let decoder = BoxDecoder()

do {
    // MARK: - Encode
    
    let data = try encoder.encode(people)
    
    print("Only \(data.count) bytes !!!! (I think 137 bytes.) for 10000 people.")
    
    // MARK: - Decode
    
    let decoded = try decoder.decode(Array<Person>.self, from: data)
    
    print(decoded[0]) // Alice
}
