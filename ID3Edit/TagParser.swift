
//
//  TagParser.swift
//  ID3Edit
//
//  Created by Philip Hardy on 1/9/16.
//  Copyright © 2016 Hardy Creations. All rights reserved.
//

import Foundation

internal class TagParser
{
    typealias Byte = UInt8
    
    let BYTE = 8
    
    // MARK: - Instance Variables
    let data: Data?
    let tag: ID3Tag
    
    init(data: Data?, tag: ID3Tag)
    {
        self.data = data
        self.tag = tag
    }
    
    // MARK: - Tag Analysis
    
    internal func analyzeData()
    {
        let tagPresent = isTagPresent()
        if tagPresent.present && tagPresent.version
        {
            // Loop through frames until reach the end of the tag
            extractInfoFromFrames(tagSize: getTagSize())
        }
    }
    
    
    internal func isTagPresent() -> (present: Bool, version: Bool)
    {
        // Determine if a tag is present
        let header = ID3Tag.frame.header.rawValue
        var isPresent = false
        var isCorrectVersion = false
        data!.withUnsafeBytes{ (bytes: UnsafePointer<Byte>)->Void in
            for i in 0 ..< 3
            {
                isPresent = isPresent && (bytes[i] == header[i])
            }
            
            isCorrectVersion = bytes[3] == header[3]
        }
        return (isPresent, isCorrectVersion)
        
    }
    
    // MARK: - Extraction Methods
    
    private func extractInfoFromFrames(tagSize: Int)
    {
        // Get the tag
        data!.withUnsafeBytes{ (pointer: UnsafePointer<Byte>)->Void in  // UnsafePointer<Byte>(data!.bytes) + ID3Tag.TAG_OFFSET
            
            
            let ptr = pointer + ID3Tag.TAG_OFFSET
            // Loop through all the frames
            var curPosition = 0
            while curPosition < tagSize
            {
                let bytes = ptr + curPosition
                let frameBytes: [Byte] = [bytes[0], bytes[1], bytes[2]]
                let frameSizeBytes: [Byte] = [bytes[3], bytes[4], bytes[5]]
                let frameSize = getFrameSize(frameSizeBytes: frameSizeBytes)
                
                
                // Extract info from current frame if needed
                if let frame = ID3Tag.frame(rawValue: frameBytes)
                {
                    let data = Data(bytes: bytes + frame.offset, count: frameSize - frame.offset)
                    let isPNG = frame == .artwork && bytes[7] != 0x4A
                    extractInfo(data: data, frameSize: frameSize, frame: frame, isPNG: isPNG)
                }
                    
                // Check for padding in order to break out
                else if frameBytes[0] == 0 && frameBytes[1] == 0 && frameBytes[2] == 0
                {
                    break
                }
                
                // Jump to next frame and move up current position
                curPosition += frameSize
            }
        }
    }
    
    
    private func extractInfo(data: Data, frameSize: Int, frame: ID3Tag.frame, isPNG: Bool = true)
    {
        let content: String = frame != .artist ? (String(data: data, encoding: .ascii) ?? "") : ""
        switch frame {
        case .artist:
            tag.artist = content
        case .title:
            tag.title = content
        case .album:
            tag.album = content
        case .composer:
            tag.composer = content
        case .trackNo:
            tag.trackNo = content
        case .year:
            tag.year = content
        case .copyright:
            tag.copyright = content
        case .publisher:
           tag.publisher = content
        case .lyrics:
            tag.lyrics = content
        case .artwork:
            tag.set(artwork: data, isPNG: isPNG)
        case .header:
            break
        }
    }
    
    
    private func getFrameSize(frameSizeBytes: [Byte]) -> Int
    {
        // Calculate the size of the frame
        var size = ID3Tag.FRAME_OFFSET
        var shift = 2 * BYTE
        
        for i in 0 ..< 3
        {
            size += Int(frameSizeBytes[i]) << shift
            shift -= BYTE
        }
        
        // Return the frame size including the frame header
        return size
    }
    
    
    internal func getTagSize() -> Int
    {
        return data!.withUnsafeBytes{ (pointer: UnsafePointer<Byte>) -> Int in
            let ptr = pointer + ID3Tag.FRAME_OFFSET
            
            var size = 0
            var shift = 21
            
            for i in 0 ..< 4
            {
                size += Int(ptr[i]) << shift
                shift -= 7
            }
            
            return size
        }
    }
}
