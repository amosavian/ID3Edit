
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
        let header = ID3Tag.FRAMES.HEADER
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
    
    
    private func isUseful(frame: [Byte]) -> Bool
    {
        // Determine if the frame is useful
        return isArtistFrame(frame: frame) || isTitleFrame(frame: frame) || isAlbumFrame(frame:frame) || isArtworkFrame(frame:frame) || isLyricsFrame(frame:frame)
    }
    
    
    private func isLyricsFrame(frame: [Byte]) -> Bool
    {
        return frame == ID3Tag.FRAMES.LYRICS
    }
    
    
    private func isArtistFrame(frame: [Byte]) -> Bool
    {
        return frame == ID3Tag.FRAMES.ARTIST
    }
    
    
    private func isAlbumFrame(frame: [Byte]) -> Bool
    {
        return frame == ID3Tag.FRAMES.ALBUM
    }
    
    
    private func isTitleFrame(frame: [Byte]) -> Bool
    {
        return frame == ID3Tag.FRAMES.TITLE
    }
    
    
    private func isArtworkFrame(frame: [Byte]) -> Bool
    {
        return frame == ID3Tag.FRAMES.ARTWORK
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
                if isUseful(frame: frameBytes)
                {
                    extractInfo(bytes: bytes, frameSize: frameSize, frameBytes: frameBytes)
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
    
    
    private func extractInfo(bytes: UnsafePointer<Byte>, frameSize: Int, frameBytes: [Byte])
    {
        
        if bytes.pointee == 0x54 // Starts with 'T' (Artist, Title, or Album)
        {
            // Frame holds text content
            let content = NSString(bytes: bytes + ID3Tag.FRAME_OFFSET, length: frameSize - ID3Tag.FRAME_OFFSET, encoding: String.Encoding.ascii.rawValue) as! String
            
            if isArtistFrame(frame: frameBytes)
            {
                // Store artist
                tag.set(artist: content)
            }
            else if isTitleFrame(frame: frameBytes)
            {
                // Store title
                tag.set(title: content)
            }
            else
            {
                // Store album
                tag.set(album: content)
            }
        }
        else if bytes.pointee == 0x55 // Starts with 'U' (Lyrics)
        {
            // Get lyrics
            let content = NSString(bytes: bytes + ID3Tag.LYRICS_FRAME_OFFSET, length: frameSize - ID3Tag.LYRICS_FRAME_OFFSET, encoding: String.Encoding.ascii.rawValue) as! String
            
            // Store the lyrics
            tag.set(lyrics: content)
        }
        else // Leaves us with artwork
        {
            // Frame holds artwork
            let isPNG = bytes[7] != 0x4A // Doesn't equal 'J' for JPG
            let artData = NSData(bytes: bytes + ID3Tag.ART_FRAME_OFFSET, length: frameSize - ID3Tag.ART_FRAME_OFFSET)
            tag.set(artwork: artData, isPNG: isPNG)
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
