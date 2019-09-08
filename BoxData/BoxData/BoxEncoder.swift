//===----------------------------------------------------------------------===//
//
// This source file is part of the Box project.
//
// Copyright (c) 2019 Obuchi Yuki
// This source file is released under the MIT License.
//
// See http://opensource.org/licenses/mit-license.php for license information
//
//===----------------------------------------------------------------------===//

import Foundation

public class BoxEncoder {
    
    /// Initializes `self` with default strategies.
    public init() {}
    
    // MARK: - Encoding Values
    
    /// Encodes the given top-level value and returns its Box representation.
    public func encode<T: Encodable>(_ value:T) throws -> Data {
        let encoder = _BoxEncoder()
        
        guard let topLevel = try encoder.box_(value) else {
            throw EncodingError.invalidValue(value,
                                             EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }
        
        
        
        fatalError()
    }
}

internal class _BoxEncoder: Encoder {
    var codingPath = [CodingKey]()
    
    var userInfo = [CodingUserInfoKey : Any]()
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        fatalError()
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }
}

extension _BoxEncoder {
    fileprivate func box_(_ value: Encodable) throws -> CompoundTag? {
        fatalError()
    }
}

internal class _BoxSerialization {
    static func data(withBoxTag boxTag: Dictionary<String,Any>) throws -> Data {
        fatalError()
    }
}
