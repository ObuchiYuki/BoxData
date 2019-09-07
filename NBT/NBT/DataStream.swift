//
//  DataStream.swift
//  NBTCoder
//
//  Created by yuki on 2019/09/06.
//  Copyright © 2019 yuki. All rights reserved.
//


import Foundation
import CoreGraphics

// ======================================================================== //
// MARK: - DataStreamError -
enum DataStreamError: Error {
    /// Error happend while reading
    case readError
    
    /// Error happend while wrting
    case writeError
}

// ======================================================================== //
// MARK: - DataReadStream -
public class DataReadStream {

    // ======================================================================== //
    // MARK: - Properties -
    private var inputStream: InputStream
    private let bytes: Int
    private var offset: Int = 0
    
    // ======================================================================== //
    // MARK: - Constructor -
    public init(data: Data) {
        self.inputStream = InputStream(data: data)
        self.inputStream.open()
        self.bytes = data.count
    }

    deinit {
        self.inputStream.close()
    }

    // ======================================================================== //
    // MARK: - Access -
    public var hasBytesAvailable: Bool {
        return self.inputStream.hasBytesAvailable
    }
    
    public var bytesAvailable: Int {
        return self.bytes - self.offset
    }
    
    // ======================================================================== //
    // MARK: - Methods -
    public func readBytes<T>() throws -> T {
        let valueSize = MemoryLayout<T>.size
        let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        var buffer = [UInt8](repeating: 0, count: MemoryLayout<T>.stride)
        let bufferPointer = UnsafeMutablePointer<UInt8>(&buffer)
        if self.inputStream.read(bufferPointer, maxLength: valueSize) != valueSize {
            
            throw DataStreamError.readError
        }
        bufferPointer.withMemoryRebound(to: T.self, capacity: 1) {
            valuePointer.pointee = $0.pointee
        }
        offset += valueSize
        return valuePointer.pointee
    }

    public func int8() throws -> Int8 {
        return try self.readBytes()
    }
    public func uInt8() throws -> UInt8 {
        return try self.readBytes()
    }

    public func int16() throws -> Int16 {
        let value:UInt16 = try self.readBytes()
        return Int16(bitPattern: CFSwapInt16BigToHost(value))
    }
    public func uint16() throws -> UInt16 {
        let value:UInt16 = try self.readBytes()
        return CFSwapInt16BigToHost(value)
    }

    public func int32() throws -> Int32 {
        let value:UInt32 = try self.readBytes()
        return Int32(bitPattern: CFSwapInt32BigToHost(value))
    }
    public func uInt32() throws -> UInt32 {
        let value:UInt32 = try self.readBytes()
        return CFSwapInt32BigToHost(value)
    }

    public func int64() throws -> Int64 {
        let value:UInt64 = try self.readBytes()
        return Int64(bitPattern: CFSwapInt64BigToHost(value))
    }
    public func uInt64() throws -> UInt64 {
        let value:UInt64 = try self.readBytes()
        return CFSwapInt64BigToHost(value)
    }

    public func float() throws -> Float {
        let value:CFSwappedFloat32 = try self.readBytes()
        return CFConvertFloatSwappedToHost(value)
    }

    public func double() throws -> Double {
        let value:CFSwappedFloat64 = try self.readBytes()
        return CFConvertFloat64SwappedToHost(value)
    }

    public func data(count: Int) throws -> Data {
        var buffer = [UInt8](repeating: 0, count: count)
        if self.inputStream.read(&buffer, maxLength: count) != count {
            
            throw DataStreamError.readError
        }
        offset += count
        return Data(buffer)
    }

    public func bit() throws -> Bool {
        let byte = try self.uInt8() as UInt8
        return byte != 0
    }
    
}

// ======================================================================== //
// MARK: - DataWriteStream -
public class DataWriteStream {

    // ======================================================================== //
    // MARK: - Properties -
    private var outputStream: OutputStream

    // ======================================================================== //
    // MARK: - Construcotr -
    public init() {
        self.outputStream = OutputStream.toMemory()
        self.outputStream.open()
    }

    deinit {
        self.outputStream.close()
    }

    // ======================================================================== //
    // MARK: - Access -
    public var data: Data? {
        return self.outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
    }
    
    // ======================================================================== //
    // MARK: - Methods -
    public func writeBytes<T>(value: T) throws {
        let valueSize = MemoryLayout<T>.size
        var value = value
        var result = false
        let valuePointer = UnsafeMutablePointer<T>(&value)
        let _ = valuePointer.withMemoryRebound(to: UInt8.self, capacity: valueSize) {
            result = (outputStream.write($0, maxLength: valueSize) == valueSize)
        }
        if !result { throw DataStreamError.writeError }
    }

    public func write(_ value: Int8) throws {
        try writeBytes(value: value)
    }
    public func write(_ value: UInt8) throws {
        try writeBytes(value: value)
    }

    public func write(_ value: Int16) throws {
        try writeBytes(value: CFSwapInt16HostToBig(UInt16(bitPattern: value)))
    }
    public func write(_ value: UInt16) throws {
        try writeBytes(value: CFSwapInt16HostToBig(value))
    }

    public func write(_ value: Int32) throws {
        try writeBytes(value: CFSwapInt32HostToBig(UInt32(bitPattern: value)))
    }
    public func write(_ value: UInt32) throws {
        try writeBytes(value: CFSwapInt32HostToBig(value))
    }

    public func write(_ value: Int64) throws {
        try writeBytes(value: CFSwapInt64HostToBig(UInt64(bitPattern: value)))
    }
    public func write(_ value: UInt64) throws {
        try writeBytes(value: CFSwapInt64HostToBig(value))
    }
    
    public func write(_ value: Float32) throws {
        try writeBytes(value: CFConvertFloatHostToSwapped(value))
    }
    public func write(_ value: Float64) throws {
        try writeBytes(value: CFConvertFloat64HostToSwapped(value))
    }
    public func write(_ data: Data) throws {
        var bytesWritten = 0
        
        data.withUnsafeBytes { bytesWritten = outputStream.write($0, maxLength: data.count) }
        if bytesWritten != data.count { throw DataStreamError.writeError }
    }
    
    public func write(_ value: Bool) throws {
        try writeBytes(value: UInt8(value ? 0xff : 0x00))
    }
}
