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
// Error Utilities
//===----------------------------------------------------------------------===//
extension DecodingError {
    /// Returns a `.typeMismatch` error describing the expected type.
    ///
    /// - parameter path: The path of `CodingKey`s taken to decode a value of this type.
    /// - parameter expectation: The type expected to be encountered.
    /// - parameter reality: The value that was encountered instead of the expected type.
    /// - returns: A `DecodingError` with the appropriate path and debug description.
    internal static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(_typeDescription(of: reality)) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }

    /// Returns a description of the type of `value` appropriate for an error message.
    ///
    /// - parameter value: The value whose type to describe.
    /// - returns: A string describing `value`.
    /// - precondition: `value` is one of the types below.
    fileprivate static func _typeDescription(of value: Any) -> String {
        if value is NSNull {
            return "a null value"
        } else if value is NSNumber {
            return "a number"
        } else if value is String {
            return "a string/data"
        } else if value is [Any] {
            return "an array"
        } else if value is [String : Any] {
            return "a dictionary"
        } else {
            return "\(type(of: value))"
        }
    }
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
        // If an existing unkeyed container was already requested, return that one.
        let topContainer: ListTag
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushUnkeyedContainer()
        } else {
            guard let container = self.storage.containers.last as? ListTag else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }

        return _BoxUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
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

extension _BoxEncoder : SingleValueEncodingContainer {
    // MARK: - SingleValueEncodingContainer Methods
    fileprivate func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
    }

    public func encodeNil() throws {
        assertCanEncodeNewValue()
        self.storage.push(container: EndTag.shared)
    }

    public func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode<T : Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
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
        let array: ListTag
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
        return _BoxReferencingEncoder(referencing: self.encoder, key: _BoxKey.super, wrapping: self.container)
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
    private let container: ListTag

    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]

    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.value.count
    }

    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _BoxEncoder, codingPath: [CodingKey], wrapping container: ListTag) {
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

    fileprivate mutating func pushUnkeyedContainer() -> ListTag {
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

// MARK: - _BoxReferencingEncoder

fileprivate class _BoxReferencingEncoder : _BoxEncoder {
    // MARK: Reference types.
    /// The type of container we're referencing.
    private enum Reference {
        /// Referencing a specific index in an array container.
        case array(ListTag, Int)

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
    fileprivate init(referencing encoder: _BoxEncoder, at index: Int, wrapping array: ListTag) {
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

//===----------------------------------------------------------------------===//
// Box Decoder
//===----------------------------------------------------------------------===//

public class BoxDecoder {
    // MARK: - Constructing a Box Decoder
    
    /// Initializes `self` with default strategies.
    public init() {}
    
    // MARK: - Decoding Values
    
    /// Decodes a top-level value of the given type from the given Box representation.
    open func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let topLevel: Tag
        do {
           topLevel = try _BoxSerialization.boxObject(with: data)
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid Box.", underlyingError: error))
        }

        let decoder = _BoxDecoder(referencing: topLevel)
        guard let value = try decoder.unbox(topLevel, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }

        return value
    }
}

// MARK: - _BoxDecoder

fileprivate class _BoxDecoder : Decoder {
    // MARK: Properties
    /// The decoder's storage.
    fileprivate var storage: _BoxDecodingStorage

    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]

    /// Don't use.
    public var userInfo = [CodingUserInfoKey : Any]()

    // MARK: - Initialization
    
    /// Initializes `self` with the given top-level container and options.
    fileprivate init(referencing container: Tag, at codingPath: [CodingKey] = []) {
        self.storage = _BoxDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
    }

    // MARK: - Decoder Methods
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard !(self.storage.topContainer is EndTag) else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self,
                    DecodingError.Context(codingPath: self.codingPath,
                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard let topContainer = self.storage.topContainer as? CompoundTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: CompoundTag.self, reality: self.storage.topContainer)
        }

        let container = _BoxKeyedDecodingContainer<Key>(referencing: self, wrapping: topContainer)
        return KeyedDecodingContainer(container)
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !(self.storage.topContainer is EndTag) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get unkeyed decoding container -- found null value instead."))
        }

        guard let topContainer = self.storage.topContainer as? ListTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: self.storage.topContainer)
        }

        return _BoxUnkeyedDecodingContainer(referencing: self, wrapping: topContainer)
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

// MARK: - Decoding Storage

fileprivate struct _BoxDecodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the Box types
    private(set) fileprivate var containers: [Tag] = []

    // MARK: - Initialization
    
    /// Initializes `self` with no containers.
    fileprivate init() {}

    // MARK: - Modifying the Stack
    
    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate var topContainer: Tag {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.last!
    }

    fileprivate mutating func push(container: __owned Tag) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        self.containers.removeLast()
    }
}

// MARK: Decoding Containers

fileprivate struct _BoxKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K

    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: _BoxDecoder

    /// A reference to the container we're reading from.
    private let container: CompoundTag

    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]

    // MARK: - Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: _BoxDecoder, wrapping container: CompoundTag) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }

    // MARK: - KeyedDecodingContainerProtocol Methods
    
    public var allKeys: [Key] {
        return self.container.value.keys.compactMap { Key(stringValue: $0) }
    }

    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }

    private func _errorDescription(of key: CodingKey) -> String {
        return "\(key) (\"\(key.stringValue)\")"
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        return entry is EndTag
    }

    public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \(_errorDescription(of: key))"))
        }

        guard let dictionary = value as? CompoundTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }

        let container = _BoxKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }

    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \(_errorDescription(of: key))"))
        }

        guard let array = value as? ListTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }

        return _BoxUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    private func _superDecoder(forKey key: __owned CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        let value: Tag = self.container[key.stringValue] ?? EndTag.shared
        return _BoxDecoder(referencing: value, at: self.decoder.codingPath)
    }

    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: _BoxKey.super)
    }

    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}


fileprivate struct _BoxUnkeyedDecodingContainer : UnkeyedDecodingContainer {
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: _BoxDecoder

    /// A reference to the container we're reading from.
    private let container: ListTag

    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]

    /// The index of the element we're about to decode.
    private(set) public var currentIndex: Int

    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: _BoxDecoder, wrapping container: ListTag) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }

    // MARK: - UnkeyedDecodingContainer Methods
    public var count: Int? {
        return self.container.value.count
    }

    public var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }

    public mutating func decodeNil() throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        if self.container.value[self.currentIndex] is EndTag {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }

    public mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int.Type) throws -> Int {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int8.Type) throws -> Int8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int16.Type) throws -> Int16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Float.Type) throws -> Float {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Double.Type) throws -> Double {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: String.Type) throws -> String {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode<T : Decodable>(_ type: T.Type) throws -> T {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container.value[self.currentIndex], as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_BoxKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container.value[self.currentIndex]
        guard !(value is EndTag) else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard let dictionary = value as? CompoundTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }

        self.currentIndex += 1
        let container = _BoxKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container.value[self.currentIndex]
        guard !(value is EndTag) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard let array = value as? ListTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }

        self.currentIndex += 1
        return _BoxUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    public mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(_BoxKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
        }

        let value = self.container.value[self.currentIndex]
        self.currentIndex += 1
        return _BoxDecoder(referencing: value, at: self.decoder.codingPath)
    }
}

extension _BoxDecoder : SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    
    private func expectNonNull<T>(_ type: T.Type) throws {
        guard !self.decodeNil() else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) but found null value instead."))
        }
    }

    public func decodeNil() -> Bool {
        return self.storage.topContainer is EndTag
    }

    public func decode(_ type: Bool.Type) throws -> Bool {
        try expectNonNull(Bool.self)
        return try self.unbox(self.storage.topContainer, as: Bool.self)!
    }

    public func decode(_ type: Int.Type) throws -> Int {
        try expectNonNull(Int.self)
        return try self.unbox(self.storage.topContainer, as: Int.self)!
    }

    public func decode(_ type: Int8.Type) throws -> Int8 {
        try expectNonNull(Int8.self)
        return try self.unbox(self.storage.topContainer, as: Int8.self)!
    }

    public func decode(_ type: Int16.Type) throws -> Int16 {
        try expectNonNull(Int16.self)
        return try self.unbox(self.storage.topContainer, as: Int16.self)!
    }

    public func decode(_ type: Int32.Type) throws -> Int32 {
        try expectNonNull(Int32.self)
        return try self.unbox(self.storage.topContainer, as: Int32.self)!
    }

    public func decode(_ type: Int64.Type) throws -> Int64 {
        try expectNonNull(Int64.self)
        return try self.unbox(self.storage.topContainer, as: Int64.self)!
    }

    public func decode(_ type: UInt.Type) throws -> UInt {
        try expectNonNull(UInt.self)
        return try self.unbox(self.storage.topContainer, as: UInt.self)!
    }

    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        try expectNonNull(UInt8.self)
        return try self.unbox(self.storage.topContainer, as: UInt8.self)!
    }

    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        try expectNonNull(UInt16.self)
        return try self.unbox(self.storage.topContainer, as: UInt16.self)!
    }

    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        try expectNonNull(UInt32.self)
        return try self.unbox(self.storage.topContainer, as: UInt32.self)!
    }

    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        try expectNonNull(UInt64.self)
        return try self.unbox(self.storage.topContainer, as: UInt64.self)!
    }

    public func decode(_ type: Float.Type) throws -> Float {
        try expectNonNull(Float.self)
        return try self.unbox(self.storage.topContainer, as: Float.self)!
    }

    public func decode(_ type: Double.Type) throws -> Double {
        try expectNonNull(Double.self)
        return try self.unbox(self.storage.topContainer, as: Double.self)!
    }

    public func decode(_ type: String.Type) throws -> String {
        try expectNonNull(String.self)
        return try self.unbox(self.storage.topContainer, as: String.self)!
    }

    public func decode<T : Decodable>(_ type: T.Type) throws -> T {
        try expectNonNull(type)
        return try self.unbox(self.storage.topContainer, as: type)!
    }
}

// MARK: - Concrete Value Representations


extension _BoxDecoder {
    fileprivate func unbox(_ value: Tag, as type: Bool.Type) throws -> Bool? {
        guard !(value is EndTag) else { return nil }

        if let number = value as? ByteTag {
            return number.bool
        }

        throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    fileprivate func unbox(_ value: Tag, as type: Int.Type) throws -> Int? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? SwiftIntTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }
        
        return Int(number.value)
    }
    
    fileprivate func unbox(_ value: Tag, as type: Int8.Type) throws -> Int8? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? ByteTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return number.value
    }
    
    fileprivate func unbox(_ value: Tag, as type: Int16.Type) throws -> Int16? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? ShortTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return number.value
    }
    
    fileprivate func unbox(_ value: Tag, as type: Int32.Type) throws -> Int32? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? IntTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return number.value
    }
    
    fileprivate func unbox(_ value: Tag, as type: Int64.Type) throws -> Int64? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? LongTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return number.value
    }
    
    fileprivate func unbox(_ value: Tag, as type: UInt.Type) throws -> UInt? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? SwiftIntTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        let uint = UInt(bitPattern: Int(number.value))
        return uint
    }
    
    fileprivate func unbox(_ value: Tag, as type: UInt8.Type) throws -> UInt8? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? ByteTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        let uint = UInt8(bitPattern: number.value)
        return uint
    }
    
    fileprivate func unbox(_ value: Tag, as type: UInt16.Type) throws -> UInt16? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? ShortTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        let uint = UInt16(bitPattern: number.value)
        return uint
    }
    
    fileprivate func unbox(_ value: Tag, as type: UInt32.Type) throws -> UInt32? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? IntTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        let uint = UInt32(bitPattern: number.value)
        return uint
    }
    
    fileprivate func unbox(_ value: Tag, as type: UInt64.Type) throws -> UInt64? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? LongTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        let uint = UInt64(bitPattern: number.value)
        return uint
    }
    
    fileprivate func unbox(_ value: Tag, as type: Float.Type) throws -> Float? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? FloatTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return number.value
    }
    
    fileprivate func unbox(_ value: Tag, as type: Double.Type) throws -> Double? {
        guard !(value is EndTag) else { return nil }

        guard let number = value as? DoubleTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return number.value
    }
    
    fileprivate func unbox(_ value: Tag, as type: String.Type) throws -> String? {
        guard !(value is EndTag) else { return nil }

        guard let string = value as? StringTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return string.value
    }
    
    fileprivate func unbox(_ value: Tag, as type: Date.Type) throws -> Date? {
        guard !(value is EndTag) else { return nil }
        
        let double = try self.unbox(value, as: Double.self)!
        return Date(timeIntervalSince1970: double)
    }
    
    fileprivate func unbox(_ value: Tag, as type: Data.Type) throws -> Data? {
        guard !(value is EndTag) else { return nil }
        
        guard let list = value as? ListTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }
        
        let elements = list.value
            .compactMap({$0 as? ByteTag})
            .map({$0.value!})
            .map{UInt8(bitPattern: $0)}
        
        return Data.init(elements)
    }
    
    fileprivate func unbox<T>(_ value: Tag, as type: _BoxStringDictionaryDecodableMarker.Type) throws -> T? {
        guard !(value is EndTag) else { return nil }

        var result = [String : Any]()
        guard let dict = value as? CompoundTag else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }
        let elementType = type.elementType
        for (key, value) in dict.value {
            let key = key
            self.codingPath.append(_BoxKey(stringValue: key)!)
            defer { self.codingPath.removeLast() }

            result[key] = try unbox_(value, as: elementType)
        }

        return result as? T
    }
    
    fileprivate func unbox<T : Decodable>(_ value: Tag, as type: T.Type) throws -> T? {
        return try unbox_(value, as: type) as? T
    }
    
    fileprivate func unbox_(_ value: Tag, as type: Decodable.Type) throws -> Any? {
        if type == Date.self || type == NSDate.self {
            return try self.unbox(value, as: Date.self)
        } else if type == Data.self || type == NSData.self {
            return try self.unbox(value, as: Data.self)
        } else if type == URL.self || type == NSURL.self {
            guard let urlString = try self.unbox(value, as: String.self) else {
                return nil
            }

            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath,
                                                                        debugDescription: "Invalid URL string."))
            }
            return url
        } else if type == Decimal.self || type == NSDecimalNumber.self {
            return try self.unbox(value, as: Decimal.self)
        } else if let stringKeyedDictType = type as? _BoxStringDictionaryDecodableMarker.Type {
            return try self.unbox(value, as: stringKeyedDictType)
        } else {
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try type.init(from: self)
        }
    }
}

//===----------------------------------------------------------------------===//
// Shared Key Types
//===----------------------------------------------------------------------===//
fileprivate struct _BoxKey : CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }

    fileprivate init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    fileprivate static let `super` = _BoxKey(stringValue: "super")!
}


//===----------------------------------------------------------------------===//
// Box Serialization
//===----------------------------------------------------------------------===//


internal class _BoxSerialization {
    static func boxObject(with data: Data) throws -> Tag {
        let stream = BoxDataReadStream(data: data)
        
        return try Tag.deserialize(from: stream)
    }
    
    static func data(withBoxTag boxTag: Tag) throws -> Data {
        let stream = BoxDataWriteStream()
        
        try boxTag.serialize(into: stream)
        
        guard let data = stream.data else {
            throw BoxDataStreamError.writeError
        }
        
        return data
    }
}
