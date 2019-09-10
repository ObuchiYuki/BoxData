// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import BoxData

class TableOfContentsSpec: QuickSpec {
    // MARK: - Codable Data
    struct Region: Codable {
        let sections:[[[Section]]]
        
        struct Section: Codable {
            let anchor: UInt16
            let fill: UInt16
            let fillAnchor: UInt16
            let data: UInt8
        }
    }
    
    private func createData() -> Region {
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        
        Region(sections:
        )
    }
    
    func testNormal() {
        let encoder = BoxEncoder()
        let decoder = BoxDecoder()
        
        
    }
}
