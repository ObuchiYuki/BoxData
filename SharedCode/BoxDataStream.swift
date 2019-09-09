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

/// Error from DataStream
enum BoxDataStreamError: Error {
    case readError
    case writeError
}


@usableFromInline
internal class BoxDataReadStream {

    private var inputStream: InputStream
    private let bytes: Int
    private var offset: Int = 0
    
    init(data: Data) {
        self.inputStream = InputStream(data: data)
        self.inputStream.open()
        self.bytes = data.count
    }

    deinit {
        self.inputStream.close()
    }

    var hasBytesAvailable: Bool {
        return self.inputStream.hasBytesAvailable
    }
    
    var bytesAvailable: Int {
        return self.bytes - self.offset
    }
    
    func readBytes<T>() throws -> T {
        let valueSize = MemoryLayout<T>.size
        let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        var buffer = [UInt8](repeating: 0, count: MemoryLayout<T>.stride)
        let bufferPointer = UnsafeMutablePointer<UInt8>(&buffer)
        if self.inputStream.read(bufferPointer, maxLength: valueSize) != valueSize {
            
            throw BoxDataStreamError.readError
        }
        bufferPointer.withMemoryRebound(to: T.self, capacity: 1) {
            valuePointer.pointee = $0.pointee
        }
        offset += valueSize
        return valuePointer.pointee
    }

    func int8() throws -> Int8 {
        return try self.readBytes()
    }
    func uInt8() throws -> UInt8 {
        return try self.readBytes()
    }

    func int16() throws -> Int16 {
        let value:UInt16 = try self.readBytes()
        return Int16(bitPattern: CFSwapInt16BigToHost(value))
    }
    func uint16() throws -> UInt16 {
        let value:UInt16 = try self.readBytes()
        return CFSwapInt16BigToHost(value)
    }

    func int32() throws -> Int32 {
        let value:UInt32 = try self.readBytes()
        return Int32(bitPattern: CFSwapInt32BigToHost(value))
    }
    func uInt32() throws -> UInt32 {
        let value:UInt32 = try self.readBytes()
        return CFSwapInt32BigToHost(value)
    }

    func int64() throws -> Int64 {
        let value:UInt64 = try self.readBytes()
        return Int64(bitPattern: CFSwapInt64BigToHost(value))
    }
    func uInt64() throws -> UInt64 {
        let value:UInt64 = try self.readBytes()
        return CFSwapInt64BigToHost(value)
    }

    func float() throws -> Float {
        let value:CFSwappedFloat32 = try self.readBytes()
        return CFConvertFloatSwappedToHost(value)
    }

    func double() throws -> Double {
        let value:CFSwappedFloat64 = try self.readBytes()
        return CFConvertFloat64SwappedToHost(value)
    }

    func data(count: Int) throws -> Data {
        var buffer = [UInt8](repeating: 0, count: count)
        if self.inputStream.read(&buffer, maxLength: count) != count {
            
            throw BoxDataStreamError.readError
        }
        offset += count
        return Data(buffer)
    }
    
    func string() throws -> String {
        let count = try uInt8()
        
        guard let string = String(bytes: try self.data(count: Int(count)), encoding: .utf8) else {
            throw BoxDataStreamError.readError
        }
        
        return string
    }

    func bit() throws -> Bool {
        let byte = try self.uInt8() as UInt8
        return byte != 0
    }
    
}

@usableFromInline
internal class BoxDataWriteStream {

    private var outputStream: OutputStream

    init() {
        self.outputStream = OutputStream.toMemory()
        self.outputStream.open()
    }

    deinit {
        self.outputStream.close()
    }

    var data: Data? {
        return self.outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
    }
    
    func writeBytes<T>(value: T) throws {
        let valueSize = MemoryLayout<T>.size
        var value = value
        var result = 0
        
        let valuePointer = UnsafeMutablePointer<T>(&value)
        _ = valuePointer.withMemoryRebound(to: UInt8.self, capacity: valueSize) {
            result = outputStream.write($0, maxLength: valueSize)
        }
            
        if result < 0 {
            throw BoxDataStreamError.writeError
        }
    }

    func write(_ value: Int8) throws {
        try writeBytes(value: value)
    }
    func write(_ value: UInt8) throws {
        try writeBytes(value: value)
    }

    func write(_ value: Int16) throws {
        try writeBytes(value: CFSwapInt16HostToBig(UInt16(bitPattern: value)))
    }
    func write(_ value: UInt16) throws {
        try writeBytes(value: CFSwapInt16HostToBig(value))
    }

    func write(_ value: Int32) throws {
        try writeBytes(value: CFSwapInt32HostToBig(UInt32(bitPattern: value)))
    }
    func write(_ value: UInt32) throws {
        try writeBytes(value: CFSwapInt32HostToBig(value))
    }

    func write(_ value: Int64) throws {
        try writeBytes(value: CFSwapInt64HostToBig(UInt64(bitPattern: value)))
    }
    func write(_ value: UInt64) throws {
        try writeBytes(value: CFSwapInt64HostToBig(value))
    }
    
    func write(_ value: Float32) throws {
        try writeBytes(value: CFConvertFloatHostToSwapped(value))
    }
    func write(_ value: Float64) throws {
        try writeBytes(value: CFConvertFloat64HostToSwapped(value))
    }
    func write(_ data: Data) throws {
        var bytesWritten = 0
        
        data.withUnsafeBytes {
            bytesWritten = outputStream.write($0, maxLength: data.count)
        }
        
        if bytesWritten != data.count {
            
            throw BoxDataStreamError.writeError
        }
    }
    
    func write(_ string:String) throws {
        if string.isEmpty { return }
        guard let data = string.data(using: .utf8) else {return}
        
        try self.write(UInt8(data.count))
        try self.write(data)
    }
    
    func write(_ value: Bool) throws {
        try writeBytes(value: UInt8(value ? 0xff : 0x00))
    }
}
