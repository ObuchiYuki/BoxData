//
//  Ex+DataStream.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

class ReadStreamStringReadingError: Error { }

extension ReadStreamStringReadingError: LocalizedError {
    var localizedDescription: String {
        return "Cannot encode value."
    }
}

extension DataWriteStream {
    public func write(_ string:String) throws {
        if string.isEmpty { return }
        guard let data = string.data(using: .utf8) else {return}
        
        try self.write(UInt8(data.count))
        try self.write(data)
    }
}

extension DataReadStream {
    public func string() throws -> String {
        let count = try uInt8()
        
        guard let string = String(bytes: try self.data(count: Int(count)), encoding: .utf8) else {
            throw ReadStreamStringReadingError()
        }
        
        return string
    }
}
