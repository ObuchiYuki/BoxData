// https://github.com/Quick/Quick

import Quick
import Nimble
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

class TableOfContentsSpec: QuickSpec {
    
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
