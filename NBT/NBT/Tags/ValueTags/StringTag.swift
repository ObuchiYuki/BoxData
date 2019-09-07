//
//  StringTag.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class StringTag: ArrayTag<String> {
    
    override func tagID() -> TagID { .string }
    
    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        
        try dos.write(value!)
    }
    
    override public func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        
        self.value = try dis.string()
    }
    
    override public func valueString(maxDepth: Int) -> String {
        return value ?? "nil"
    }
}
