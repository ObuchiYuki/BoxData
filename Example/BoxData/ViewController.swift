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
struct Region: Codable {
    let sections:[[[Section]]]
    
    struct Section: Codable {
        let anchor: UInt16
        let fill: UInt16
        let fillAnchor: UInt16
        let data: UInt8
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
            
        // MARK: - Prepare Data
        let air = Region.Section(anchor: 0, fill: 0, fillAnchor: 0, data: 0)
        let region = Region(sections: Array(repeating: Array(repeating: Array(repeating: air, count: 100), count: 5), count: 100))
                
        // MARK: - Coders
        let encoder = BoxEncoder()
        encoder.useCompression = false
        encoder.useStructureCache = false
        let decoder = BoxDecoder()
        
        do {
            let data = try encoder.encode(region)
            
            print("Just only \(data.count)bytes!!!!!")
            
            let decoded = try decoder.decode(Region.self, from: data)
            
            print(decoded.sections[0][0][0])
            
        } catch {
            print(error)
        }
    }
}

