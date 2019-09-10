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


class TableOfContentsSpec: XCTestCase {
    
    func testMain() {
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        let region = Region(sections: Array(repeating: Array(repeating: Array(repeating: air, count: 1), count: 1), count: 1))
        
        // MARK: - Coders
        let encoder = BoxEncoder()
        encoder.useCompression = false
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
        encoder.useCompression = false
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
        encoder.useCompression = false
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
