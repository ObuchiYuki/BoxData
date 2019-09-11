import XCTest
@testable import BoxData

// MARK: - Codable Data
struct Region: Codable {
    let sections:[[[Section]]]
    
    struct Section: Codable, Equatable {
        let anchor: UInt16
        let fill: UInt16
        let fillAnchor: UInt16
        let data: UInt8
    }
}

struct Person: Codable {
  let name: String
  let age: UInt8
  let birth:Conutry
  
    struct Conutry: Codable {
    let name: String
    let id: UInt8
  }
}


class TableOfContentsSpec: XCTestCase {
    

    func testCompression() {
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        let testData = Region(sections: Array(repeating: Array(repeating: Array(repeating: air, count: 100), count: 5), count: 100) )
        
        let encoder = BoxEncoder()
        let decoder = BoxDecoder()
        
        do {
            for i in 0...6 {
                encoder.compressionLevel = UInt8(i)
                let data = try encoder.encode(testData)
                let decoded = try decoder.decode(Region.self, from: data)
                XCTAssertEqual(decoded.sections[0][0][0], air)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testReadme() {
        let alice = Person(name: "Alice", age: 16, birth: .init(name: "UK"     , id: 12))
        let bob   = Person(name: "Bob"  , age: 22, birth: .init(name: "America", id: 14))
        
        /// 10000 data
        let people = Array(repeating: alice, count: 5000) + Array(repeating: bob, count: 5000)
        
        do {
            let data = try BoxEncoder().encode(people)
            
            print(data) // Just only 144 bytes !!!!!
            
            let decoded = try BoxDecoder().decode(Array<Person>.self, from: data)
            
            print(decoded[0])
            
        } catch {
            print(error)
        }
        
        
    }
    
    func testMain() {
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        let region = Region(sections: Array(repeating: Array(repeating: Array(repeating: air, count: 1), count: 1), count: 1))
        
        // MARK: - Coders
        let encoder = BoxEncoder()
        encoder.compressionLevel = 0
        let decoder = BoxDecoder()
        
        do {
            let data = try encoder.encode(region)
            
            print("Just only \(data.count)bytes!!!!!")
            
            print()
            for i in data {
                print(String(format:"%02X", i), separator: "", terminator: "")
            }
            print()
            let decoded = try decoder.decode(Region.self, from: data)
            
            print(decoded.sections[0][0][0])
            
        } catch {
            print(error)
        }
    }
    
    func testNoCompressionNoStructure() {
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        
        let testData = Region(sections: Array(repeating: Array(repeating: Array(repeating: air, count: 100), count: 5), count: 100) )
        
        let encoder = BoxEncoder()
        encoder.compressionLevel = 1
        encoder.useStructureCache = false
        let decoder = BoxDecoder()
        
        do {
            let data = try encoder.encode(testData)
            
            let decoded = try decoder.decode(Region.self, from: data)
            
            XCTAssertEqual(decoded.sections[0][0][0], air)
            
        } catch {
            XCTFail("\(error)")
        }
        
    }
    
    func testNoCompression() {
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        
        let testData = Region(sections: Array(repeating: Array(repeating: Array(repeating: air, count: 100), count: 5), count: 100) )
        
        let encoder = BoxEncoder()
        encoder.compressionLevel = 1
        let decoder = BoxDecoder()
        
        do {
            let data = try encoder.encode(testData)
            
            let decoded = try decoder.decode(Region.self, from: data)
            
            XCTAssertEqual(decoded.sections[0][0][0], air)
            
        } catch {
            XCTFail("\(error)")
        }
        
    }
    
    func testNoStructure() {
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        
        let testData = Region(sections: Array(repeating: Array(repeating: Array(repeating: air, count: 100), count: 5), count: 100) )
        
        let encoder = BoxEncoder()
        encoder.useStructureCache = false
        let decoder = BoxDecoder()
        
        do {
            let data = try encoder.encode(testData)
            
            let decoded = try decoder.decode(Region.self, from: data)
            
            XCTAssertEqual(decoded.sections[0][0][0], air)
            
        } catch {
            XCTFail("\(error)")
        }
        
    }
    
    func testNormal() {
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        
        let testData = Region(sections: Array(repeating: Array(repeating: Array(repeating: air, count: 100), count: 5), count: 100) )
        
        let encoder = BoxEncoder()
        let decoder = BoxDecoder()
        
        do {
            let data = try encoder.encode(testData)
            
            let decoded = try decoder.decode(Region.self, from: data)
            
            XCTAssertEqual(decoded.sections[0][0][0], air)
            
        } catch {
            XCTFail("\(error)")
        }
        
    }
}
