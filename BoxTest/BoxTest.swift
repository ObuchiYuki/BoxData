//
//  BoxTest.swift
//  BoxTest
//
//  Created by yuki on 2019/09/08.
//  Copyright © 2019 yuki. All rights reserved.
//

import XCTest
@testable import BoxData

struct Person1:Codable {
    let name:String
    let age:UInt8
}

class BoxTest: XCTestCase {
    let encoder = BoxEncoder()
    let decoder = BoxDecoder()
    
    func testNormalClass() {
        do {
            let alice = Person1(name: "Alice", age: 16)
            let encodedAlice = try encoder.encode(alice)
            
            let decodedAlice = try decoder.decode(Person1.self, from: encodedAlice)
            
            XCTAssertEqual(decodedAlice.name, "Alice")
            XCTAssertEqual(decodedAlice.age, 16)
            
        } catch {
            XCTFail("\(error)")
        }
    }
}
