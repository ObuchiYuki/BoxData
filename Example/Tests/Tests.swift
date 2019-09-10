// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import BoxData

class TableOfContentsSpec: QuickSpec {
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
    
    private func createData() -> Region {
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        
        return Region(sections: Array(repeating: Array(repeating: Array(repeating: air, count: 100), count: 5), count: 100) )
    }
    
    func testNormal() {
        let testData = createData()
        
        let encoder = BoxEncoder()
        let decoder = BoxDecoder()
        
        do {
            let data = try encoder.encode(testData)
            
            let decoded = try decoder.decode(Region.self, from: data)
            
            XCTAssertEqual(decoded.sections[0][0][0].anchor, 0)
            
        } catch {
            XCTFail("\(error)")
        }
        
    }
}
