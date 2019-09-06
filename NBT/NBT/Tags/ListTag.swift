//
//  ListTag.swift
//  NBT
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation

public class ListTag<U, T: Tag<U>>: Tag<[T]> {
    
    public var size:Int32 {
        return Int32(value!.count)
    }

    public func remove(index:Int) -> T? {
        return value?.remove(at: index)
    }
    public func clear() {
        value = []
    }
    
    public func append(_ t:T) {
        self.value?.append(t)
    }
    
    override public func serializeValue(into dos: DataWriteStream, maxDepth: Int) throws {
        dos.write(TagFactory.idFromClass<T>())
        dos.write(size)
        if (size() != 0) {
            for (T t : getValue()) {
                t.serializeValue(dos, decrementMaxDepth(maxDepth));
            }
        }
    }
    
    override public func deserializeValue(into dis: DataReadStream, maxDepth: Int) throws {
        int typeID = dis.readByte();
        if (typeID != 0) {
            typeClass = TagFactory.classFromID(typeID);
        }
        int size = dis.readInt();
        size = size < 0 ? 0 : size;
        setValue(createEmptyValue(size));
        if (size != 0) {
            for (int i = 0; i < size; i++) {
                Tag<?> tag = TagFactory.fromID(typeID);
                tag.deserializeValue(dis, decrementMaxDepth(maxDepth));
                add((T) tag);
            }
        }
    }
    
    override public func valueString(maxDepth: Int) -> String {
        value.map{"\($0)"} ?? "nil"
    }
}
