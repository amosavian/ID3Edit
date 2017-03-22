//
//  MP3File.swift
//  ID3Edit
//
//  Created by Philip Hardy on 1/6/16.
//  Copyright © 2016 Hardy Creations. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
    import UIKit
    public typealias ImageClass = UIImage
#elseif os(macOS)
    import Cocoa
    public typealias ImageClass = NSImage
#endif

/**
 Opens an MP3 file for reading and writing the ID3 tag
 
 - Parameter path: The path to the MP3 file
 - Parameter overwrite: Overwrite the ID3 tag in the file if one exists. (Default value is false)
 
 **Note**: If there is an ID3 tag present but not of version 2.x the ID3 tag will be overwritten when the new tag is written
 
 - Throws: `ID3EditErrors.FileDoesNotExist` if the file at the given path does not exist or `ID3EditErrors.NotAnMP3` if the file is not an MP3
 */
open class MP3File
{
    
    typealias Byte = UInt8
    
    
    // MARK: - Constants
    fileprivate let BYTE = 8
    
    // MARK: - Instance Variables
    fileprivate let parser: TagParser?
    fileprivate let tag: ID3Tag = ID3Tag()
    fileprivate let path: String?
    fileprivate let data: Data?
    
    
    
    public init(path: String, overwrite: Bool = false) throws
    {
        // Store the url in order to write to it later
        self.path = path
        
        // Get the data from the file
        data = try? Data(contentsOf: URL(fileURLWithPath: path))
        parser = TagParser(data: data, tag: tag)
        
        if data == nil
        {
            // The file does not exist
            throw ID3EditErrors.fileDoesNotExist
        }
        
        // Check the path extension
        if (path as NSString).pathExtension.caseInsensitiveCompare("mp3") != ComparisonResult.orderedSame
        {
            throw ID3EditErrors.notAnMP3
        }
        
        // Analyze the data
        if !overwrite
        {
            parser!.analyzeData()
        }
    }
    
    
    public init(data: Data?, overwrite: Bool = false) throws
    {
        
        self.data = data
        parser = TagParser(data: data, tag: tag)
        
        if data == nil
        {
            throw ID3EditErrors.noDataExists
        }
        
        // Analyze the data
        if !overwrite
        {
            parser!.analyzeData()
        }
        path = ""
    }
    
    
    // MARK: - Accessor Methods
    
    /**
     Returns the artwork for this file
     
     - Returns: An `NSImage/UIImage` if artwork exists and `nil` otherwise
     */
    open var artwork: ImageClass?
    {
        get {
            return tag.getArtwork()
        }
    }
    
    /**
     Returns the artist for the file
     
     - Returns: The song artist or a blank `String` if not available
     */
    open var artist: String
    {
        get {
            return tag.getArtist()
        }
        set {
            tag.set(artist: artist)
        }
    }
    
    
    /**
     Returns the title of the song
     
     - Returns: The song title or a blank `String` if not available
     */
    open var title: String
    {
        get {
            return tag.getTitle()
        }
        set {
            tag.set(title: title)
        }
    }
    
    
    /**
     Returns the album of the song
     
     - Returns: The song album or a blank `String` if not available
     */
    open var album: String
    {
        get {
            return tag.getAlbum()
        }
        set {
            tag.set(album: album)
        }
    }
    
    /**
     Returns the lyrics for the ID3 tag
     
     - Returns: The lyrics for the ID3 tag or a blank `String` if not available
     */
    open var lyrics: String {
        get {
            return tag.getLyrics()
        }
        set {
            tag.set(lyrics: lyrics)
        }
    }
    
    /**
     Sets the artwork for the ID3 tag
     
     - Parameter artwork: The art to be used when the tag is written
     - Parameter isPNG: Whether the art is in PNG format or JPG
     
     - Note: The artwork can only be PNG or JPG
     */
    open func set(artwork: ImageClass, isPNG: Bool)
    {
        tag.set(artwork: artwork, isPNG: isPNG)
    }
    
    /**
     Sets the artwork for the ID3 tag
     
     - Parameter artwork: The art to be used when the tag is written
     - Parameter isPNG: Whether the art is in PNG format or JPG
     
     - Note: The artwork can only be PNG or JPG
     */
    open func set(artworkData: Data, isPNG: Bool)
    {
        tag.set(artwork: artworkData as NSData, isPNG: isPNG)
    }
    
    // MARK: - Tag Creation Methods
    
    /**
     Writes the new tag to the file
     
     - Returns: `true` if writes successfully, `false` otherwise
     - Throws: Throws `ID3EditErrors.TagSizeOverflow` if tag size is over 256MB
     */
    open func writeTag(to path: String) throws -> Bool
    {
        do
        {
            let newData = try getMP3Data()
            
            // Write the tag to the file
            if (try newData.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil
            {
                return true
            }
            else
            {
                return false
            }
        }
        catch let err
        {
            throw err
        }
    }
    
    /**
     Returns the MP3 file data with the new tag included
     
     - Returns: The MP3 data with the new tag included
     - Note: The data is ready to write to a file
     */
    open func getMP3Data() throws -> Data
    {
        
        if data == nil
        {
            // Prevent writing if there is no data
            throw ID3EditErrors.noDataExists
        }
        
        // Get the tag bytes
        let content = tag.getBytes()
        
        if content.count == 0
        {
            return data!
        }
        else if content.count > 0xFFFFFFF
        {
            throw ID3EditErrors.tagSizeOverflow
        }
        
        // Form the binary data
        let newData = NSMutableData(bytes: content, length: content.count)
        
        var tagSize: Int
        
        if parser!.isTagPresent().present
        {
            tagSize = parser!.getTagSize() + ID3Tag.TAG_OFFSET
        }
        else
        {
            tagSize = 0
        }
        
        let music = (data! as NSData).bytes + tagSize
        newData.append(music, length: data!.count - tagSize)
        
        return newData as Data
    }
}
