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
