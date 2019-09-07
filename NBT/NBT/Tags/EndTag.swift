//
//  EndTag.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public final class EndTag: Tag<Int> {

    static let shared = EndTag()

    required init(value: Int? = nil) {
        super.init(value: nil)
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
