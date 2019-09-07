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
        guard let data = string.data(using: .utf8) else {return}

        try self.write(data)
    }
}

extension DataReadStream {
    public func string(count:UInt32) throws -> String {
        
        guard let string = String(bytes: try self.data(count: Int(count)), encoding: .utf8) else {
            throw ReadStreamStringReadingError()
        }
        
        return string
    }
}
