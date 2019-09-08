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
// MARK: - TagID -
//===----------------------------------------------------------------------===//

/// Tag id with rawValue UInt8.
/// This rawValue is equals to saved value.
@usableFromInline
enum TagID: UInt8 {
    case end            = 0
    case byte           = 1
    case short          = 2
    case int            = 3
    case long           = 4
    case float          = 5
    case double         = 6
    case byteArray      = 7
    case string         = 8
    case list           = 9
    case compound       = 10
    case intArray       = 11
    case longArray      = 12
}


//===----------------------------------------------------------------------===//
// MARK: - TagFactory -
//===----------------------------------------------------------------------===//
@usableFromInline
final internal class TagFactory {
    static func idFromType<T: Tag>(_ type:T.Type) -> TagID {
        if T.self == EndTag.self         {return .end}
        if T.self == ByteTag.self        {return .byte}
        if T.self == ShortTag.self       {return .short}
        if T.self == IntTag.self         {return .int}
        if T.self == LongTag.self        {return .long}
        if T.self == FloatTag.self       {return .float}
        if T.self == DoubleTag.self      {return .double}
        if T.self == ByteArrayTag.self   {return .byteArray}
        if T.self == StringTag.self      {return .string}
        if T.self == ListTag.self        {return .list}
        if T.self == CompoundTag.self    {return .compound}
        if T.self == IntArrayTag.self    {return .intArray}
        if T.self == LongArrayTag.self   {return .longArray}
        
        fatalError("Not matching tag")
    }
    
    static func fromID(id: UInt8) -> Tag {
        switch TagID(rawValue: id)! {
        case .end:      return EndTag.shared
        case .byte:     return ByteTag(value: nil)
        case .short:    return ShortTag(value: nil)
        case .int:      return IntTag(value: nil)
        case .long:     return LongTag(value: nil)
        case .float:    return FloatTag(value: nil)
        case .double:   return DoubleTag(value: nil)
        case .byteArray:return ByteArrayTag(value: nil)
        case .string:   return StringTag(value: nil)
        case .list:     return ListTag(value: nil)
        case .compound: return CompoundTag(value: nil)
        case .intArray: return IntArrayTag(value: nil)
        case .longArray:return LongArrayTag(value: nil)
        }
    }
}

//===----------------------------------------------------------------------===//
// MARK: - Tag -
//===----------------------------------------------------------------------===//


/// # Class `Tag`
///
/// Represents non value type Tag. If use want to use tag with value use ValueTag instead.
///
/// Tag serialization
/// ### for Normal tag
/// `| tag_id | name | value |`
///
/// ### for End tag
/// `| tag_id |`
@usableFromInline
internal class Tag {
    
    /// Subclass of Tag must implement tagID() to return own type.
    fileprivate func tagID() -> TagID {
        fatalError("Subclass of Tag must implement tagID().")
    }
    
    // MARK: - Methods -
    
    ///
    //@usableFromInline
    //final func serialize(into dos: DataWriteStream, maxDepth:Int) throws {
    //
    //
    //    serialize(into: dos, maxDepth: maxDepth)
    //}
    
    /// This method must be called from outside as root object.
    @usableFromInline
    final func serialize(into dos:BoxDataWriteStream, maxDepth:Int = Tag.defaultMaxDepth) throws {
        try dos.write(UInt8(0x42)) // 'B'
        try dos.write(UInt8(1))   // version
        
        try _serialize(into: dos, named: "", maxDepth: maxDepth)
    }
 
    /// serialize data with name. for component
    final fileprivate func _serialize(into dos:BoxDataWriteStream, named name:String, maxDepth: Int) throws {
        let id = tagID()
        try dos.write(id.rawValue)
        
        if (id != .end) {
            try dos.write(name)
        }
        
        try serializeValue(into: dos, maxDepth: maxDepth)
    }

    /// deserialize input.
    static internal func deserialize(from dis: BoxDataReadStream, maxDepth:Int = Tag.defaultMaxDepth) throws -> Tag {
        let filetag = try dis.uInt8()
        precondition(filetag == 0x42, "This file is not BoxData format.")
        let version = try dis.uInt8()
        precondition(version == 1, "This BoxData format file is not version 1.0.")
        
        let id = try dis.uInt8()
        let tag = TagFactory.fromID(id: id)
        
        if (id != 0) {
            try tag.deserializeValue(from: dis, maxDepth: maxDepth);
        }
        
        return tag
    }
    
    /// decrement maxDepth use this method to decrease maxDepth.
    /// This method check if maxDepth match requirement.
    final fileprivate func decrementMaxDepth(_ maxDepth: Int) -> Int {
        assert(maxDepth > 0, "negative maximum depth is not allowed")
        assert(maxDepth != 0, "reached maximum depth of NBT structure")
        
        return maxDepth - 1
    }
    
    
    // MARK: - Overridable Methods
    // Subclass of Tag must override those methods below to implement function.
    
    /// Subclass of Tag must override this method to serialize value.
    fileprivate func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        fatalError("Subclass of Tag must implement serializeValue(into:, _:).")
    }
    
    /// Subclass of Tag must override this method to deserialize value.
    fileprivate func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        fatalError("Subclass of Tag must implement deserializeValue(from:, _:).")
    }
    
    /// Subclass of Tag must override this method to retuen description of Value.
    fileprivate func valueString(maxDepth: Int) -> String {
        fatalError("Subclass of Tag must implement valueString(maxDepth:)")
    }
}

extension Tag {
     
    /// defalt max depth of deserialize.
    @usableFromInline
    static let defaultMaxDepth = 512
}

extension Tag: CustomStringConvertible {
    
    @usableFromInline
    var description: String {
        return valueString(maxDepth: Tag.defaultMaxDepth)
    }
}

//===----------------------------------------------------------------------===//
// MARK: - ValueTag -
//===----------------------------------------------------------------------===//

/// # Class `ValueTag<T>`
///
/// This class represents tag with value. Use generics to represent value type.
/// All Tag with value must stem from this class.
@usableFromInline
internal class ValueTag<T>: Tag {
    
    /// The type of value contained in ValueTag.
    @usableFromInline
    typealias Element = T
    
    /// The value of tag.
    /// Initirized from `init(value:)` or `deserializeValue(_:,_:)`
    @usableFromInline
    var value: T!
    
    /// The initirizer of `ValueTag`. You can initirize `ValueTag` value with nil or some
    @usableFromInline
    init(value:T? = nil) {
        self.value = value
    }
    
    /// This method returns the description of `ValueTag`.
    @inlinable
    @inline(__always)
    override func valueString(maxDepth: Int) -> String {
        return value.map{"\($0)"} ?? "nil"
    }
}

/// `ValueTag` with `Equatable` type can be `Equatable`.
extension ValueTag: Equatable where Element: Equatable {
    @inlinable
    static func == (left:ValueTag, right:ValueTag) -> Bool {
        return left.value == right.value
    }
}

/// `ValueTag` with `Hashable` type can be `Hashable`.
extension ValueTag: Hashable where Element: Hashable {
    @inlinable
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

//===----------------------------------------------------------------------===//
// MARK: - Implemention of Tags -
//===----------------------------------------------------------------------===//

//===----------------------------------===//
// MARK: - EndTag -
//===----------------------------------===//


/// This tag represents Compound end or represents NULL
/// Use like this
///
/// `| compound_tag |...| end_tag |`
/// or
/// `| EndTag |`
///
/// Compound type read file while reaches this tag.
@usableFromInline
final internal class EndTag: Tag {

    /// Shared instance of `EndTag`.
    @usableFromInline
    static let shared = EndTag()
    
    /// Make `EndTag`'s init inaccessible.
    private override init() {
        super.init()
    }
    
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.writeBytes(value: TagID.end.rawValue)
    }
    
    @inlinable
    final override func valueString(maxDepth: Int) -> String {
        return "\"end\""
    }
}

//===----------------------------------===//
// MARK: - ByteTag -
//===----------------------------------===//

/// This class represents tag of `Int8`.
///
/// ### Serialize structure
///
/// | tag_id | 1 byte |
@usableFromInline
internal final class ByteTag: ValueTag<Int8> {
    
    /// Initirize ByteTag with Bool value.
    internal init(flag: Bool) {
        super.init(value: flag ? 1 : 0)
    }
    
    /// Initirize ByteTag with Int8 value.
    internal override init(value: Int8?) {
        super.init(value: value)
    }
    
    /// Bool representation of Int8.
    internal var bool: Bool {
        return value != 0
    }
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .byte }
    
    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(value)
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        self.value = try dis.int8()
    }
}

//===----------------------------------===//
// MARK: - ShortTag -
//===----------------------------------===//

/// This class represents tag of `Int16`.
///
/// ### Serialize structure
///
/// | tag_id | 2 bytes |
@usableFromInline
internal final class ShortTag: ValueTag<Int16> {
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .short }
    
    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(value)
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        self.value = try dis.int16()
    }
}

//===----------------------------------===//
// MARK: - IntTag -
//===----------------------------------===//

/// This class represents tag of `Int32`.
///
/// ### Serialize structure
///
/// | tag_id | 4 bytes |
@usableFromInline
internal final class IntTag: ValueTag<Int32> {

    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .int }
    
    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(value)
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        self.value = try dis.int32()
    }
}

//===----------------------------------===//
// MARK: - LongTag -
//===----------------------------------===//

/// This class represents tag of `Int64`.
///
/// ### Serialize structure
///
/// | tag_id | 8 bytes |
@usableFromInline
internal final class LongTag: ValueTag<Int64> {
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .long }
    
    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(value)
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        self.value = try dis.int64()
    }
}

//===----------------------------------===//
// MARK: - LongTag -
//===----------------------------------===//

/// This class represents tag of `Float`.
///
/// ### Serialize structure
///
/// | tag_id | 4 bytes |
@usableFromInline
internal final class FloatTag: ValueTag<Float> {
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .float }
    
    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(value)
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        self.value = try dis.float()
    }
}

//===----------------------------------===//
// MARK: - DoubleTag -
//===----------------------------------===//

/// This class represents tag of `Double`.
///
/// ### Serialize structure
///
/// | tag_id | 8 bytes |
@usableFromInline
internal final class DoubleTag: ValueTag<Double> {
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .double }
    
    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(value)
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        self.value = try dis.double()
    }
}

//===----------------------------------===//
// MARK: - StringTag -
//===----------------------------------===//

/// This class represents tag of `String`.
/// Max String length is 255
///
/// ### Serialize structure
///
/// | tag_id | length(1 bytes) | data(UTF)... |
@usableFromInline
internal final class StringTag: ValueTag<String> {
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .string }
    
    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(value)
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        self.value = try dis.string()
    }
}

//===----------------------------------===//
// MARK: - ByteArrayTag -
//===----------------------------------===//

/// This class represents tag of `[Int8]`.
///
/// ### Serialize structure
///
/// | tag_id | length (4 bytes) | data...(1byte...) |
@usableFromInline
internal final class ByteArrayTag: ValueTag<[Int8]> {
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .longArray }

    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(UInt32(value.count))
        
        try value.forEach{
            try dos.write($0)
        }
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        let length = try dis.uInt32()
        var _value = [Int8]()
        
        for _ in 0..<length {
            _value.append(try dis.int8())
        }
        
        self.value = _value
    }
}

//===----------------------------------===//
// MARK: - IntArrayTag -
//===----------------------------------===//

/// This class represents tag of `[Int32]`.
///
/// ### Serialize structure
///
/// | tag_id | length (4 bytes) | data...(4byte...) |
@usableFromInline
internal final class IntArrayTag: ValueTag<[Int32]> {
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .intArray }

    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(UInt32(value.count))
        
        try value.forEach{
            try dos.write($0)
        }
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        let length = try dis.uInt32()
        var _value = [Int32]()
        
        for _ in 0..<length {
            _value.append(try dis.int32())
        }
        
        self.value = _value
    }
}


//===----------------------------------===//
// MARK: - LongArrayTag -
//===----------------------------------===//

/// This class represents tag of `[Int64]`.
///
/// ### Serialize structure
///
/// | tag_id | length (4 bytes) | data...(8byte...) |
@usableFromInline
internal final class LongArrayTag: ValueTag<[Int64]> {
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .longArray }

    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(UInt32(value.count))
        
        try value.forEach{
            try dos.write($0)
        }
    }
    
    @usableFromInline
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        let length = try dis.uInt32()
        var _value = [Int64]()
        
        for _ in 0..<length {
            _value.append(try dis.int64())
        }
        
        self.value = _value
    }
}

//===----------------------------------===//
// MARK: - CompoundTag -
//===----------------------------------===//

/// This class represents tag of `[Int64]`.
///
/// ### Serialize structure
///
/// | tag_id | (| name(StringTag) | value(ValueTag) |)... | EndTag |
@usableFromInline
internal final class CompoundTag: ValueTag<[String: Tag]> {
    
    internal subscript(_ name:String) -> Tag? {
        set { value[name] = newValue }
        get { return value[name] }
    }
    
    @inlinable
    final override func tagID() -> TagID { .compound }
        
    @usableFromInline
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        for (key, value) in value {
            try value._serialize(into: dos, named: key, maxDepth: decrementMaxDepth(maxDepth))
        }
        try EndTag.shared.serializeValue(into: dos, maxDepth: maxDepth)
    }
    
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        self.value = [:]
        
        var id = try dis.uInt8()
        if id == 0 { /// Empty CompoundTag
            return
        }
        var name = try dis.string()
        
        while true {
            let tag = TagFactory.fromID(id: id)
            try tag.deserializeValue(from: dis, maxDepth: decrementMaxDepth(maxDepth))
            
            value[name] = tag
            
            id = try dis.uInt8()
            if id == 0 { /// Read until End tag.
                break
            }
            name = try dis.string()
        }
    }
}

//===----------------------------------===//
// MARK: - ListTag -
//===----------------------------------===//

/// This class represents tag of `[Tag]`.
///
/// ListTag contains single type of tag.
/// You must not put multiple type of tag into ListTag.
///
/// ### Serialize structure
///
/// ##### Empty
///
/// `| tag_id | length(4 bytes) = 0 | `
///
/// ##### Not Empty
///
/// `| tag_id | length(4 bytes) | value_tag_id (1 bytes) | ( value(ValueTag) )... |`
@usableFromInline
internal final class ListTag: ValueTag<[Tag]> {
    
    internal func add(_ tag:Tag) {
        self.value.append(tag)
    }
    
    @inlinable
    @inline(__always)
    final override func tagID() -> TagID { .list }
    
    final override func serializeValue(into dos: BoxDataWriteStream, maxDepth: Int) throws {
        try dos.write(UInt32(value.count))
        
        guard !value.isEmpty else { return }
        
        try dos.write(value[0].tagID().rawValue)
        
        for element in value {
            try element.serializeValue(into: dos, maxDepth: decrementMaxDepth(maxDepth))
        }
    }
    
    final override func deserializeValue(from dis: BoxDataReadStream, maxDepth: Int) throws {
        self.value = []
        
        let size = try dis.uInt32()
        guard size != 0 else { return }
        
        let typeId = try dis.uInt8()
        
        for _ in 0..<size {
            
            let tag = TagFactory.fromID(id: typeId)
            try tag.deserializeValue(from: dis, maxDepth: decrementMaxDepth(maxDepth))
            
            self.value.append(tag)
        }
    }
}
