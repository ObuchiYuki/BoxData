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

/// Determine `Int` type based on running environment.
#if (arch(i386) || arch(arm)) // 32bit
typealias SwiftIntTag = IntTag
#else // 64bit
typealias SwiftIntTag = LongTag
#endif

/// A marker protocol used to determine whether a value is a `String`-keyed `Dictionary`
/// containing `Encodable` values (in which case it should be exempt from key conversion strategies).
fileprivate protocol _BoxStringDictionaryEncodableMarker { }

extension Dictionary : _BoxStringDictionaryEncodableMarker where Key == String, Value: Encodable { }

/// A marker protocol used to determine whether a value is a `String`-keyed `Dictionary`
/// containing `Decodable` values (in which case it should be exempt from key conversion strategies).
fileprivate protocol _BoxStringDictionaryDecodableMarker {
    static var elementType: Decodable.Type { get }
}

extension Dictionary : _BoxStringDictionaryDecodableMarker where Key == String, Value: Decodable {
    static var elementType: Decodable.Type { return Value.self }
}

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
            EncodingError.Context(codingPath: [], debugDescription: "Unable to encode the given top-level value to Box.", underlyingError: error))
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
        let topContainer: CompoundTag
        
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushKeyedContainer()
        } else {
            guard let container = self.storage.containers.last as? CompoundTag else {
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
    /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
    fileprivate func box(_ value: Bool)   -> Tag { return ByteTag       (flag: value) }
    fileprivate func box(_ value: Int)    -> Tag { return SwiftIntTag   (value: Int64(value)) }
    fileprivate func box(_ value: Int8)   -> Tag { return ByteTag       (value: value) }
    fileprivate func box(_ value: Int16)  -> Tag { return ShortTag      (value: value) }
    fileprivate func box(_ value: Int32)  -> Tag { return IntTag        (value: value) }
    fileprivate func box(_ value: Int64)  -> Tag { return LongTag       (value: value) }
    fileprivate func box(_ value: UInt)   -> Tag { return SwiftIntTag   (value: Int64(bitPattern: UInt64(value))) }
    fileprivate func box(_ value: UInt8)  -> Tag { return ByteTag       (value: Int8 (bitPattern: value)) }
    fileprivate func box(_ value: UInt16) -> Tag { return ShortTag      (value: Int16(bitPattern: value)) }
    fileprivate func box(_ value: UInt32) -> Tag { return IntTag        (value: Int32(bitPattern: value)) }
    fileprivate func box(_ value: UInt64) -> Tag { return LongTag       (value: Int64(bitPattern: value)) }
    
    fileprivate func box(_ value: String) -> Tag { return StringTag     (value: value) }
    
    fileprivate func box(_ value: Float)  -> Tag { return FloatTag      (value: value) }
    fileprivate func box(_ value: Double) -> Tag { return DoubleTag     (value: value) }
    
    fileprivate func box(_ date:  Date)   -> Tag { return DoubleTag     (value: date.timeIntervalSince1970) }
    fileprivate func box(_ data:  Data)   -> Tag { return ByteArrayTag  (value: data.map{Int8(bitPattern: $0)}) }
    
    fileprivate func box(_ value: Encodable) throws -> Tag {
        return try self.box_(value) ?? CompoundTag(value: [:])
    }
    
    fileprivate func box(_ dict: [String : Encodable]) throws -> Tag? {
        return CompoundTag(value: try dict.mapValues{try box($0)}.compactMapValues{$0})
    }

    // This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
    fileprivate func box_(_ value: Encodable) throws -> Tag? {
        // Disambiguation between variable and function is required due to
        let type = Swift.type(of: value)
        
        if type == Date.self || type == NSDate.self {
            // Respect Date encoding strategy
            return self.box((value as! Date))
        } else if type == Data.self || type == NSData.self {
            // Respect Data encoding strategy
            return self.box((value as! Data))
        } else if type == URL.self || type == NSURL.self {
            // Encode URLs as single strings.
            return self.box((value as! URL).absoluteString)
        } else if value is _BoxStringDictionaryEncodableMarker {
            return try self.box(value as! [String : Encodable])
        }
        
        // The value should request a container from the __BoxEncoder.
        let depth = self.storage.count
        do {
                try value.encode(to: self)
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                let _ = self.storage.popContainer()
            }

            throw error
        }

        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer()
    }
}

fileprivate struct _BoxKey : CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
}

// MARK: - Encoding Containers


fileprivate struct _BoxKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    
    typealias Key = K
    
    // MARK: Properties
    
    /// A reference to the encoder we're writing to.
    private let encoder: _BoxEncoder

    /// A reference to the container we're writing to.
    private let container: CompoundTag

    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]

    // MARK: - Initialization
    
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _BoxEncoder, codingPath: [CodingKey], wrapping container: CompoundTag) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    
    mutating func encodeNil(forKey key: K) throws {
        self.container[key.stringValue] = EndTag.shared
    }
    
    mutating func encode(_ value: Bool, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: String, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: Double, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: Float, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: Int, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: Int8, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: Int16, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: Int32, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: Int64, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: UInt, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        self.container[key.stringValue] = self.encoder.box(value)
    }
    
    mutating func encode<T: Encodable>(_ value: T, forKey key: K) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let containerKey = key.stringValue
        let dictionary: CompoundTag
        if let existingContainer = self.container[containerKey] {
            precondition(
                existingContainer is CompoundTag,
                "Attempt to re-encode into nested KeyedEncodingContainer<\(Key.self)> for key \"\(containerKey)\" is invalid: non-keyed container already encoded for this key"
            )
            dictionary = existingContainer as! CompoundTag
        } else {
            dictionary = CompoundTag()
            self.container[containerKey] = dictionary
        }

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        let container = _BoxKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        let containerKey = key.stringValue
        let array: ListTag<Tag>
        if let existingContainer = self.container[containerKey] {
            precondition(
                existingContainer is ListTag,
                "Attempt to re-encode into nested UnkeyedEncodingContainer for key \"\(containerKey)\" is invalid: keyed container/single value already encoded for this key"
            )
            array = existingContainer as! ListTag
        } else {
            array = ListTag()
            self.container[containerKey] = array
        }

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return _BoxUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }
    
    mutating func superEncoder() -> Encoder {
        return _BoxReferencingEncoder(referencing: self.encoder, key: _BoxKey(index: 0), wrapping: self.container)
    }
    
    mutating func superEncoder(forKey key: K) -> Encoder {
        return _BoxReferencingEncoder(referencing: self.encoder, key: key, wrapping: self.container)
    }
    
}

fileprivate struct _BoxUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: _BoxEncoder

    /// A reference to the container we're writing to.
    private let container: ListTag<Tag>

    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]

    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.value.count
    }

    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _BoxEncoder, codingPath: [CodingKey], wrapping container: ListTag<Tag>) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    // MARK: - UnkeyedEncodingContainer Methods
    public mutating func encodeNil()             throws { self.container.add(EndTag.shared) }
    public mutating func encode(_ value: Bool)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int)    throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int8)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int16)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int32)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int64)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt8)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt16) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt32) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt64) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: String) throws { self.container.add(self.encoder.box(value)) }

    public mutating func encode(_ value: Float)  throws {
        // Since the float may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(_BoxKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.add(self.encoder.box(value))
    }

    public mutating func encode(_ value: Double) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(_BoxKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.add(self.encoder.box(value))
    }

    public mutating func encode<T : Encodable>(_ value: T) throws {
        self.encoder.codingPath.append(_BoxKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        guard let tag = try self.encoder.box_(value as Encodable) else {
            throw EncodingError.invalidValue(value,
            EncodingError.Context(codingPath: [], debugDescription: "Unable to encode the given Encodable value"))
             
        }
        self.container.add(tag)
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        self.codingPath.append(_BoxKey(index: self.count))
        defer { self.codingPath.removeLast() }

        let dictionary = CompoundTag(value: [:])
        self.container.add(dictionary)

        let container = _BoxKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self.codingPath.append(_BoxKey(index: self.count))
        defer { self.codingPath.removeLast() }

        let array = ListTag(value: [])
        self.container.add(array)
        return _BoxUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }

    public mutating func superEncoder() -> Encoder {
        return _BoxReferencingEncoder(referencing: self.encoder, at: self.container.value.count, wrapping: self.container)
    }
}

// MARK: - Encoding Storage and Containers
fileprivate struct _BoxEncodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the Box types.
    private(set) fileprivate var containers: [Tag] = []

    // MARK: - Initialization
    /// Initializes `self` with no containers.
    fileprivate init() {}

    // MARK: - Modifying the Stack
    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate mutating func pushKeyedContainer() -> CompoundTag {
        let dictionary = CompoundTag(value: [:])
        self.containers.append(dictionary)
        return dictionary
    }

    fileprivate mutating func pushUnkeyedContainer() -> ListTag<Tag> {
        let array = ListTag(value: [])
        self.containers.append(array)
        return array
    }

    fileprivate mutating func push(container: __owned Tag) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() -> Tag {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.popLast()!
    }
}

internal class _BoxSerialization {
    static func data(withBoxTag boxTag: Tag) throws -> Data {
        let stream = DataWriteStream()
        
        try boxTag.serialize(into: stream)
        
        guard let data = stream.data else {
            throw DataStreamError.writeError
        }
        
        return data
    }
}

// MARK: - _BoxReferencingEncoder

fileprivate class _BoxReferencingEncoder : _BoxEncoder {
    // MARK: Reference types.
    /// The type of container we're referencing.
    private enum Reference {
        /// Referencing a specific index in an array container.
        case array(ListTag<Tag>, Int)

        /// Referencing a specific key in a dictionary container.
        case dictionary(CompoundTag, String)
    }

    // MARK: - Properties
    /// The encoder we're referencing.
    fileprivate let encoder: _BoxEncoder

    /// The container reference itself.
    private let reference: Reference

    // MARK: - Initialization
    /// Initializes `self` by referencing the given array container in the given encoder.
    fileprivate init(referencing encoder: _BoxEncoder, at index: Int, wrapping array: ListTag<Tag>) {
        self.encoder = encoder
        self.reference = .array(array, index)
        super.init(codingPath: encoder.codingPath)

        self.codingPath.append(_BoxKey(index: index))
    }

    /// Initializes `self` by referencing the given dictionary container in the given encoder.
    fileprivate init(referencing encoder: _BoxEncoder, key: CodingKey, wrapping dictionary: CompoundTag) {
        self.encoder = encoder
        self.reference = .dictionary(dictionary, key.stringValue)
        super.init(codingPath: encoder.codingPath)

        self.codingPath.append(key)
    }

    // MARK: - Coding Path Operations
    fileprivate override var canEncodeNewValue: Bool {
        // With a regular encoder, the storage and coding path grow together.
        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
        // We have to take this into account.
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }

    // MARK: - Deinitialization
    // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
    deinit {
        let value: Tag
        switch self.storage.count {
        case 0: value = CompoundTag(value: [:])
        case 1: value = self.storage.popContainer()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }
        
        switch self.reference {
        case .array(let array, let index):
            array.value.insert(value, at: index)

        case .dictionary(let dictionary, let key):
            dictionary[key] = value
        }
    }
}
