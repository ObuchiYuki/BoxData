import Foundation


//===----------------------------------------------------------------------===//
// MARK: - TagID -
//===----------------------------------------------------------------------===//

/// Tag id with rawValue UInt8.
/// This rawValue is equals to saved value.
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

internal class TagFactory {
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
/// | tag_id | name | value |
///
/// ### for End tag
/// | tag_id |
internal class Tag {
    
    /// Subclass of Tag must implement tagID() to return own type.
    func tagID() -> TagID {
        fatalError("Subclass of Tag must implement tagID().")
    }
    
    // MARK: - Methods -
    
    /// serialize data with no name.
    /// for list, array or root tag.
    func serialize(into dos:DataWriteStream, maxDepth:Int) throws {
        
        try serialize(into: dos, named: "", maxDepth: maxDepth)
    }
 
    /// serialize data with name. for component
    func serialize(into dos:DataWriteStream, named name:String, maxDepth: Int) throws {
        let id = tagID()
        
        try dos.write(id.rawValue)
        
        if (id != .end) {
            try dos.write(name)
        }
        
        try serializeValue(into: dos, maxDepth: maxDepth)
    }

    /// deserialize input.
    static func deserialize(from dis: DataReadStream, maxDepth:Int) throws -> Tag {
        let id = try dis.uInt8()
        let tag = TagFactory.fromID(id: id)
        
        if (id != 0) {
            try tag.deserializeValue(from: dis, maxDepth: maxDepth);
        }
        
        return tag
    }
    
    /// decrement maxDepth use this method to decrease maxDepth.
    /// This method check if maxDepth match requirement.
    func decrementMaxDepth(_ maxDepth: Int) -> Int {
        assert(maxDepth > 0, "negative maximum depth is not allowed")
        assert(maxDepth != 0, "reached maximum depth of NBT structure")
        
        return maxDepth - 1
    }
    
    
    // MARK: - Overridable Methods
    // Subclass of Tag must override those methods below to implement function.
    
    /// Subclass of Tag must override this method to serialize value.
    func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        fatalError("Subclass of Tag must implement serializeValue(into:, _:).")
    }
    
    /// Subclass of Tag must override this method to deserialize value.
    func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        fatalError("Subclass of Tag must implement deserializeValue(from:, _:).")
    }
    
    /// Subclass of Tag must override this method to retuen description of Value.
    func valueString(maxDepth: Int) -> String {
        fatalError("Subclass of Tag must implement valueString(maxDepth:)")
    }
}

extension Tag {
     
    /// defalt max depth of deserialize.
    static let defaultMaxTag = 512
}

extension Tag: CustomStringConvertible {
    
    var description: String {
        return valueString(maxDepth: Tag.defaultMaxTag)
    }
}

//===----------------------------------------------------------------------===//
// MARK: - ValueTag -
//===----------------------------------------------------------------------===//

/// # Class `ValueTag<T>`
///
/// This class represents tag with value. Use generics to represent value type.
/// All Tag with value must stem from this class.
internal class ValueTag<T>: Tag {
    
    /// The type of value contained in ValueTag.
    typealias Element = T
    
    /// The value of tag.
    /// Initirized from `init(value:)` or `deserializeValue(_:,_:)`
    var value: T!
    
    /// The initirizer of `ValueTag`. You can initirize `ValueTag` value with nil or some
    init(value:T? = nil) {
        self.value = value
    }
    
    /// This method returns the description of `ValueTag`.
    override func valueString(maxDepth: Int) -> String {
        return value.map{"\($0)"} ?? "nil"
    }
}

/// `ValueTag` with `Equatable` type can be `Equatable`.
extension ValueTag: Equatable where Element: Equatable {
    
    static func == (left:ValueTag, right:ValueTag) -> Bool {
        return left.value == right.value
    }
}

/// `ValueTag` with `Hashable` type can be `Hashable`.
extension ValueTag: Hashable where Element: Hashable {
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


/// This tag represents Compound end.
/// Use like this
///
/// ```
/// | compound_tag |...| end_tag |
/// ```
/// Compound type read file while reaches this tag.
internal final class EndTag: Tag {

    /// Shared instance of `EndTag`.
    static let shared = EndTag()
    
    /// Make `EndTag`'s init inaccessible.
    private override init() {
        super.init()
    }
    
    override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.writeBytes(value: TagID.end.rawValue)
    }
    
    override func valueString(maxDepth: Int) -> String {
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
internal class ByteTag: ValueTag<Int8> {
    
    override func tagID() -> TagID { .byte }
    override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws { try dos.write(value) }
    override func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws { self.value = try dis.int8() }
}

//===----------------------------------===//
// MARK: - ShortTag -
//===----------------------------------===//

/// This class represents tag of `Int16`.
///
/// ### Serialize structure
///
/// | tag_id | 2 bytes |
internal class ShortTag: ValueTag<Int16> {
    
    override func tagID() -> TagID { .short }
    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws { try dos.write(value) }
    override public func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws { self.value = try dis.int16() }
}

//===----------------------------------===//
// MARK: - IntTag -
//===----------------------------------===//

/// This class represents tag of `Int32`.
///
/// ### Serialize structure
///
/// | tag_id | 4 bytes |
internal class IntTag: ValueTag<Int32> {

    override func tagID() -> TagID { .int }
    override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws { try dos.write(value) }
    override func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws { self.value = try dis.int32()}
}

//===----------------------------------===//
// MARK: - LongTag -
//===----------------------------------===//

/// This class represents tag of `Int64`.
///
/// ### Serialize structure
///
/// | tag_id | 8 bytes |
internal class LongTag: ValueTag<Int64> {
    
    override func tagID() -> TagID { .long }
    override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws { try dos.write(value) }
    override func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws { self.value = try dis.int64() }
}

//===----------------------------------===//
// MARK: - LongTag -
//===----------------------------------===//

/// This class represents tag of `Float`.
///
/// ### Serialize structure
///
/// | tag_id | 4 bytes |
internal class FloatTag: ValueTag<Float> {
    
    override func tagID() -> TagID { .float }
    override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws { try dos.write(value) }
    override func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws { self.value = try dis.float()}
}

//===----------------------------------===//
// MARK: - DoubleTag -
//===----------------------------------===//

/// This class represents tag of `Double`.
///
/// ### Serialize structure
///
/// | tag_id | 8 bytes |
internal class DoubleTag: ValueTag<Double> {
    
    override func tagID() -> TagID { .double }
    override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws { try dos.write(value) }
    override func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws { self.value = try dis.double() }
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
internal class StringTag: ValueTag<String> {
    
    override func tagID() -> TagID { .string }
    override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws { try dos.write(value) }
    override func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws { self.value = try dis.string() }
}

//===----------------------------------===//
// MARK: - ByteArrayTag -
//===----------------------------------===//

/// This class represents tag of `[Int8]`.
///
/// ### Serialize structure
///
/// | tag_id | length (4 bytes) | data...(1byte...) |
internal class ByteArrayTag: ValueTag<[Int8]> {
    
    override func tagID() -> TagID { .longArray }

    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(UInt32(value.count))
        try value?.forEach{try dos.write($0) }
    }
    
    override public func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        let length = try dis.uInt32()
        var _value = [Int8]()
        for _ in 0..<length { _value.append(try dis.int8()) }
        
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
internal class IntArrayTag: ValueTag<[Int32]> {
    
    override func tagID() -> TagID { .intArray }

    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(UInt32(value.count))
        try value?.forEach{try dos.write($0) }
    }
    
    override public func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        let length = try dis.uInt32()
        var _value = [Int32]()
        for _ in 0..<length { _value.append(try dis.int32()) }
        
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
internal class LongArrayTag: ValueTag<[Int64]> {
    
    override func tagID() -> TagID { .longArray }

    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(UInt32(value.count))
        try value?.forEach{try dos.write($0) }
    }
    
    override public func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        let length = try dis.uInt32()
        var _value = [Int64]()
        for _ in 0..<length { _value.append(try dis.int64()) }
        
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
internal class CompoundTag: ValueTag<[String: Tag]> {
    
    override func tagID() -> TagID { .compound }
        
    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        for (key, value) in value {
            try value.serialize(into: dos, named: key, maxDepth: decrementMaxDepth(maxDepth))
        }
        try EndTag.shared.serializeValue(into: dos, maxDepth: maxDepth)
    }
    
    override public func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        self.value = [:]
        
        var id = try dis.uInt8()
        var name = try dis.string()
        
        while true {
            let tag = TagFactory.fromID(id: id)
            try tag.deserializeValue(from: dis, maxDepth: decrementMaxDepth(maxDepth))
            
            value[name] = tag
            
            id = try dis.uInt8()
            if id == 0 {break} /// Read until End tag.
            name = try dis.string()
        }
    }
}

//===----------------------------------===//
// MARK: - ListTag -
//===----------------------------------===//

/// This class represents tag of `[Tag]`.
/// can contain all type tag.
///
/// ### Serialize structure
///
/// | tag_id | length(4 bytes) | ( value(ValueTag) )... |
internal class ListTag<T: Tag>: ValueTag<[T]> {
    override func tagID() -> TagID { .list }
    
    override func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        try dos.write(UInt32(value.count))
        
        guard !value.isEmpty else { return }
        
        for element in value {
            try element.serialize(into: dos, maxDepth: decrementMaxDepth(maxDepth))
        }
    }
    
    override func deserializeValue(from dis: DataReadStream, maxDepth: Int) throws {
        self.value = []
        
        let size = try dis.uInt32()

        guard size != 0 else { return }
        
        for _ in 0..<size {
            let typeId = try dis.uInt8()
            let tag = TagFactory.fromID(id: typeId)
            try tag.deserializeValue(from: dis, maxDepth: decrementMaxDepth(maxDepth))
            
            self.value.append(tag as! T)
        }
    }
}