//
//  EndTag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public final class EndTag: Tag {

    static let shared = EndTag()
    
    public override func serialize(into dos: DataWriteStream, maxDepth: Int) throws {}
    public override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {}
    public override func serialize(into dos: DataWriteStream, named name: String, maxDepth: Int) throws {
        try dos.write(TagID.end.rawValue)
    }
    
    public override func valueString(maxDepth: Int) -> String {
        return "\"end\""
    }
    
    public override func tagString() -> String {
        fatalError("EndTag cannot be turned into a String.")
    }
}
