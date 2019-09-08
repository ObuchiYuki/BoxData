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

//===----------------------------------------------------------------------===//
// Box Encoder
//===----------------------------------------------------------------------===//

/// `BoxEncoder` facilitates the encoding of `Encodable` values into Box.
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
        
        do {
            return try _BoxSerialization.data(withBoxTag: topLevel)
        } catch {
            throw EncodingError.invalidValue(value,
            EncodingError.Context(codingPath: [], debugDescription: "Unable to encode the given top-level value to JSON.", underlyingError: error))
        }
    }
}

// MARK: - _BoxEncoder

/// `_BoxEncoder` encodes `Codable` values.
fileprivate class _BoxEncoder: Encoder {
    
    // MARK: Properties
    
    /// The encoder's storage.
    fileprivate var storage: _BoxEncodingStorage
    
    /// The path to the current point in encoding.
    public var codingPath = [CodingKey]()
    
    /// Don't use.
    var userInfo = [CodingUserInfoKey : Any]()
    
    // MARK: - Initialization
    
    /// Initializes `self` with the given `codingPath`.
    fileprivate init(codingPath: [CodingKey] = []) {
        self.storage = _BoxEncodingStorage()
        self.codingPath = codingPath
    }
    
    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    fileprivate var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        return self.storage.count == self.codingPath.count
    }
    
    // MARK: - Encoder Methods
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let topContainer: NSMutableDictionary
        
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushKeyedContainer()
        } else {
            guard let container = self.storage.containers.last as? NSMutableDictionary else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }
        
        let container = _BoxKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }
}

extension _BoxEncoder {
    fileprivate func box_(_ value: Encodable) throws -> Tag? {
        fatalError()
    }
}

// MARK: - Encoding Storage and Containers
fileprivate struct _BoxEncodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the Box types.
    private(set) fileprivate var containers: [NSObject] = []

    // MARK: - Initialization
    /// Initializes `self` with no containers.
    fileprivate init() {}

    // MARK: - Modifying the Stack
    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate mutating func pushKeyedContainer() -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()
        self.containers.append(dictionary)
        return dictionary
    }

    fileprivate mutating func pushUnkeyedContainer() -> NSMutableArray {
        let array = NSMutableArray()
        self.containers.append(array)
        return array
    }

    fileprivate mutating func push(container: __owned NSObject) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() -> NSObject {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.popLast()!
    }
}

internal class _BoxSerialization {
    static func data(withBoxTag boxTag: Tag) throws -> Data {
        fatalError()
    }
}
