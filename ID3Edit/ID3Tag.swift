//
//  ID3Tag.swift
//  ID3Edit
//
//  Created by Philip Hardy on 1/10/16.
//  Copyright © 2016 Hardy Creations. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

internal class ID3Tag
{
    typealias Byte = UInt8
    
    // MARK: - Structs
    private struct AlbumArtwork
    {
        var art: Data?
        var isPNG: Bool?
    }
    
    private struct FRAMES
    {
        static let ARTIST: [Byte] = [0x54, 0x50, 0x31]
        static let TITLE: [Byte] = [0x54, 0x54, 0x32]
        static let ALBUM: [Byte] = [0x54, 0x41, 0x4C]
        static let COMPOSER: [Byte] = [0x54, 0x43, 0x4D]
        static let TRACKNO: [Byte] = [0x54, 0x52, 0x4B]
        static let YEAR: [Byte] = [0x54, 0x59, 0x45]
        static let COPYRIGHT: [Byte] = [0x54, 0x43, 0x52]
        static let PUBLISHER: [Byte] = [0x54, 0x50, 0x42]
        static let LYRICS: [Byte] = [0x55, 0x4C, 0x54]
        static let ARTWORK: [Byte] = [0x50, 0x49, 0x43]
        static let HEADER: [Byte] = [0x49, 0x44, 0x33, 0x02, 0x00, 0x00]
    }
    
    internal enum frame: RawRepresentable {
        case artist, title, album, composer
        case trackNo, year, copyright, publisher
        case lyrics, artwork, header
        
        typealias RawValue = [Byte]
        
        init? (rawValue: [Byte]) {
            guard rawValue.count >= 3 else { return nil }
            switch rawValue {
            case FRAMES.ARTIST: self = .artist
            case FRAMES.TITLE: self = .title
            case FRAMES.ALBUM: self = .album
            case FRAMES.COMPOSER: self = .composer
            case FRAMES.TRACKNO: self = .trackNo
            case FRAMES.YEAR: self = .year
            case FRAMES.COPYRIGHT: self = .copyright
            case FRAMES.PUBLISHER: self = .publisher
            case FRAMES.LYRICS: self = .lyrics
            case FRAMES.ARTWORK: self = .artwork
            case FRAMES.HEADER: self = .header
            default: return nil
            }
        }
        
        var rawValue: [Byte] {
            switch self {
            case .artist: return FRAMES.ARTIST
            case .title: return FRAMES.TITLE
            case .album: return FRAMES.ALBUM
            case .composer: return FRAMES.COMPOSER
            case .trackNo: return FRAMES.TRACKNO
            case .year: return FRAMES.YEAR
            case .copyright: return FRAMES.COPYRIGHT
            case .publisher: return FRAMES.PUBLISHER
            case .lyrics: return FRAMES.LYRICS
            case .artwork: return FRAMES.ARTWORK
            case .header: return FRAMES.HEADER
            }
        }
        
        var offset: Int {
            switch self {
            case .artist, .title, .album, .composer:
                fallthrough
            case .trackNo, .year, .copyright, .publisher:
                return FRAME_OFFSET
            case .lyrics:
                return LYRICS_FRAME_OFFSET
            case .artwork:
                return ART_FRAME_OFFSET
            case .header:
                return TAG_OFFSET
            }
        }
    }
    
    // MARK: - Constants
    internal static let TAG_OFFSET: Int = 10
    internal static let FRAME_OFFSET: Int = 6
    internal static let ART_FRAME_OFFSET: Int = 12
    internal static let LYRICS_FRAME_OFFSET: Int = 11
    
    // MARK: - Instance Variables
    internal var artist: String = ""
    internal var title: String = ""
    internal var album: String = ""
    internal var composer: String = ""
    internal var trackNo: String = ""
    internal var year: String = ""
    internal var copyright: String = ""
    internal var publisher: String = ""
    internal var lyrics = ""
    private var artwork = AlbumArtwork()
    
    
    // MARK: - Accessor Methods
    internal func getArtwork() -> ImageClass?
    {
        if artwork.art != nil
        {
            return ImageClass(data: artwork.art!)
        }
        
        return nil
    }
    
    internal func set(artwork: ImageClass, isPNG: Bool)
    {
        #if os(macOS)
        let imgRep = NSBitmapImageRep(data: artwork.tiffRepresentation!)
        
        if isPNG
        {
            self.artwork.art = imgRep?.representation(using: .PNG , properties: [NSImageCompressionFactor: 0.5])
        }
        else
        {
            self.artwork.art = imgRep?.representation(using: .JPEG, properties: [NSImageCompressionFactor: 0.5])
        }
        #else
        if isPNG
        {
            self.artwork.art = UIImagePNGRepresentation(artwork)
        }
        else
        {
            self.artwork.art = UIImageJPEGRepresentation(artwork, 0.5)
        }
        #endif
        
        self.artwork.isPNG = isPNG
    }
    
    internal func set(artwork: Data, isPNG: Bool)
    {
        self.artwork.art = artwork
        self.artwork.isPNG = isPNG
    }
    
    // MARK: - Tag Creation
    internal func getBytes() -> [Byte]
    {
        var content: [Byte] = []
        
        // Create the artist frame
        if let frame = create(frame: FRAMES.ARTIST, str: artist)
        {
            content.append(contentsOf: frame)
        }
        
        // Create the title frame
        if let frame = create(frame: FRAMES.TITLE, str: title)
        {
            content.append(contentsOf: frame)
        }
        
        // Create the album frame
        if let frame = create(frame: FRAMES.ALBUM, str: album)
        {
            content.append(contentsOf: frame)
        }
        
        // Create the composer frame
        if let frame = create(frame: FRAMES.COMPOSER, str: composer)
        {
            content.append(contentsOf: frame)
        }
        
        // Create the trackNo frame
        if let frame = create(frame: FRAMES.TRACKNO, str: trackNo)
        {
            content.append(contentsOf: frame)
        }
        
        // Create the year frame
        if let frame = create(frame: FRAMES.YEAR, str: year)
        {
            content.append(contentsOf: frame)
        }
        
        // Create the copyright frame
        if let frame = create(frame: FRAMES.COPYRIGHT, str: copyright)
        {
            content.append(contentsOf: frame)
        }
        
        // Create the publisher frame
        if let frame = create(frame: FRAMES.PUBLISHER, str: publisher)
        {
            content.append(contentsOf: frame)
        }
        
        // Create the lyrics frame
        if let frame = createLyricFrame()
        {
            content.append(contentsOf: frame)
        }
        
        // Create the artwork frame
        if let frame = createArtFrame()
        {
            content.append(contentsOf: frame)
        }
        
        if content.count == 0
        {
            // Prevent writing a tag header
            // if no song info is present
            return content
        }
        
        // Make the tag header
        var header = createTagHeader(contentSize: content.count)
        header.append(contentsOf: content)
        
        return header
    }
    
    private func create(frame: [Byte], str: String) -> [Byte]?
    {
        guard !str.isEmpty else { return nil }
        var bytes: [Byte] = frame
        
        var cont = [Byte](str.utf8)
        
        if cont[0] != 0
        {
            // Add padding to the beginning
            cont.insert(0, at: 0)
        }
        
        if cont.last != 0
        {
            // Add padding to the end
            cont.append(0)
        }
        
        // Add the size to the byte array
        var size = toByteArray(num: UInt32(cont.count))
        size.removeFirst()
        
        // Create the frame
        bytes.append(contentsOf: size)
        bytes.append(contentsOf: cont)
        
        // Return the completed frame
        return bytes
    }
    
    
    private func createLyricFrame() -> [Byte]?
    {
        guard !lyrics.isEmpty else { return nil }
        var bytes: [Byte] = FRAMES.LYRICS
        
        let encoding: [Byte] = [0x00, 0x65, 0x6E, 0x67, 0x00]
        
        let content = [Byte](lyrics.utf8)
        
        var size = toByteArray(num: UInt32(content.count + encoding.count))
        size.removeFirst()
        
        // Form the header
        bytes.append(contentsOf: size)
        bytes.append(contentsOf: encoding)
        bytes.append(contentsOf: content)
        
        return bytes
    }
    
    
    private func createTagHeader(contentSize: Int) -> [Byte]
    {
        var bytes: [Byte] = FRAMES.HEADER
        
        // Add the size to the byte array
        let formattedSize = UInt32(calc(size: contentSize))
        bytes.append(contentsOf: toByteArray(num: formattedSize))
        
        // Return the completed tag header
        return bytes
    }
    
    
    private func createArtFrame() -> [Byte]?
    {
        guard let art = artwork.art else { return nil }
        var bytes: [Byte] = FRAMES.ARTWORK
        
        // Calculate size
        var size = toByteArray(num: UInt32(art.count + 6))
        size.removeFirst()
        
        bytes.append(contentsOf: size)
        
        // Append encoding
        if artwork.isPNG!
        {
            // PNG encoding
            let header: [Byte] = [0x00, 0x50, 0x4E, 0x47, 0x00 ,0x00]
            bytes.append(contentsOf: header)
        }
        else
        {
            // JPG encoding
            let header: [Byte] = [0x00, 0x4A, 0x50, 0x47, 0x00 ,0x00]
            bytes.append(contentsOf: header)
        }
        
        // Add artwork data
        let data = art .withUnsafeBytes{ (bytes: UnsafePointer<Byte>)->[Byte] in
            return Array(UnsafeBufferPointer(start: bytes, count: art.count))
        }
        bytes.append(contentsOf: data)
        
        return bytes
    }
    
    // MARK: - Helper Methods
    
    
    
    private func calc(size: Int) -> Int
    {
        // Holds the size of the tag
        var newSize = 0
        
        for i in 0 ..< 4
        {
            // Get the bytes from size
            let shift = i * 8
            let mask = 0xFF << shift
            
            
            // Shift the byte down in order to use the mask
            var byte = (size & mask) >> shift
            
            var oMask: Byte = 0x80
            for _ in 0 ..< i
            {
                // Create the overflow mask
                oMask = oMask >> 1
                oMask += 0x80
            }
            
            // The left side of the byte
            let overflow = Byte(byte) & oMask
            
            // The right side of the byte
            let untouched = Byte(byte) & ~oMask
            
            // Store the byte
            byte = ((Int(overflow) << 1) + Int(untouched)) << (shift + i)
            newSize += byte
        }
        
        return newSize
    }
    
    private func toByteArray<T>(num: T) -> [Byte]
    {
        var copyNum = num
        
        let count = MemoryLayout.size(ofValue: num)
        return withUnsafePointer(to: &copyNum) {
            var data = [Byte]()
            $0.withMemoryRebound(to: Byte.self, capacity: count) {ptr in
                for i in 0 ..< count {
                    data.append(ptr[count - 1 - i])
                }
            }
            
            return data
        }
    }
}

func ~=(pattern: [ID3Tag.Byte], value: [ID3Tag.Byte]) -> Bool {
    return pattern == value
}
