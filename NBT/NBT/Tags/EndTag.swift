//
//  EndTag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public final class EndTag: AnyTag {

    static let shared = EndTag()

    required init(value: Int? = nil) {
        super.init(typeID: TagID.end.rawValue)
    }
    
    required init(typeID: UInt8) {
        fatalError("init(typeID:) has not been implemented")
    }
    
    public override func serialize(into dos: DataWriteStream, maxDepth: Int) throws {}
    public override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {}
    public override func serialize(into dos: DataWriteStream, named name: String, maxDepth: Int) throws {}
    
    public override func valueString(maxDepth: Int) -> String {
        return "\"end\""
    }
    
    public override func tagString() -> String {
        fatalError("EndTag cannot be turned into a String.")
    }
}
