//
//  ViewController.swift
//  BoxData
//
//  Created by ObuchiYuki on 09/09/2019.
//  Copyright (c) 2019 ObuchiYuki. All rights reserved.
//

import UIKit
import BoxData

// MARK: - Codable Data
struct Person: Codable {
    let name:String
    let age:UInt8
    
    let birth:Country
    
    struct Country: Codable {
        let name:String
        let id:UInt32
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
            
        // MARK: - Prepare Data
        let alice = Person(name: "Alice", age: 16, birth: .init(name: "UK"     , id: 12))
        let bob =   Person(name: "Bob"  , age: 22, birth: .init(name: "America", id: 42))
        
        let people = Array(repeating: alice, count: 5000) + Array(repeating: bob, count: 5000)
        
        // MARK: - Coders
        let encoder = BoxEncoder()
        let decoder = BoxDecoder()
        
        do {
            let data = try encoder.encode(people)
            
            print("Just only \(data.count)bytes!!!!!")  // I think 143 bytes
            
            let decoded = try decoder.decode(Array<Person>.self, from: data)
            
            print(decoded[0   ]) // Alice
            print(decoded[5000]) // Bob
            
        } catch {
            print(error)
        }
        
        
    }
}

