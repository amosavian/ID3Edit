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
        path = nil
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
            return tag.artist
        }
        set {
            tag.artist = newValue
        }
    }
    
    
    /**
     Returns the title of the song
     
     - Returns: The song title or a blank `String` if not available
     */
    open var title: String
    {
        get {
            return tag.title
        }
        set {
            tag.title = newValue
        }
    }
    
    
    /**
     Returns the album of the song
     
     - Returns: The song album or a blank `String` if not available
     */
    open var album: String
    {
        get {
            return tag.album
        }
        set {
            tag.album = newValue
        }
    }
    
    /**
     Returns the composer of the song
     
     - Returns: The song composer or a blank `String` if not available
     */
    open var composer: String {
        get {
            return tag.composer
        }
        set {
            tag.composer = newValue
        }
    }
    
    /**
     Returns the track number of the song
     
     - Returns: The song track number or a blank `String` if not available
     */
    open var trackNo: String {
        get {
            return tag.trackNo
        }
        set {
            tag.trackNo = newValue
        }
    }
    
    /**
     Returns the year of the song
     
     - Returns: The song year or a blank `String` if not available
     */
    open var year : String {
        get {
            return tag.year
        }
        set {
            tag.year = newValue
        }
    }
    
    /**
     Returns the copyright of the song
     
     - Returns: The song copyright or a blank `String` if not available
     */
    open var copyright: String {
        get {
            return tag.copyright
        }
        set {
            tag.copyright = newValue
        }
    }
    
    /**
     Returns the publisher of the song
     
     - Returns: The song publisher or a blank `String` if not available
     */
    open var publisher: String {
        get {
            return tag.publisher
        }
        set {
            tag.publisher = newValue
        }
    }
    
    /**
     Returns the lyrics for the ID3 tag
     
     - Returns: The lyrics for the ID3 tag or a blank `String` if not available
     */
    open var lyrics: String {
        get {
            return tag.lyrics
        }
        set {
            tag.lyrics = newValue
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
    open func set(artwork: Data, isPNG: Bool)
    {
        tag.set(artwork: artwork, isPNG: isPNG)
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
            try newData.write(to: URL(fileURLWithPath: path), options: [.atomic])
            return true
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
        
        guard let data = data else
        {
            // Prevent writing if there is no data
            throw ID3EditErrors.noDataExists
        }
        
        // Get the tag bytes
        let content = tag.getBytes()
        
        if content.count == 0
        {
            return data
        }
        else if content.count > 0xFFFFFFF
        {
            throw ID3EditErrors.tagSizeOverflow
        }
        
        // Form the binary data
        var newData = Data(bytes: content, count: content.count)
        
        var tagSize: Int
        
        if parser!.isTagPresent().present
        {
            tagSize = parser!.getTagSize() + ID3Tag.TAG_OFFSET
        }
        else
        {
            tagSize = 0
        }
        let music = data.subdata(in: tagSize..<(data.count - tagSize))
        newData.append(music)
        
        return newData as Data
    }
}
