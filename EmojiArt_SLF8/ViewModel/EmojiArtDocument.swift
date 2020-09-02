
//  ====================== MVVM - VIEW MODEL =============================
//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

//----------------------------
class EmojiArtDocument: ObservableObject
{
  static let palette: String = "⭐️⛈🍎🌏🥨⚾️"
  
  // @Published workaround for property observer problem with
  // property wrappers

  private var emojiArt: EmojiArt 
  {
    willSet 
    {
      objectWillChange.send()
    }
    didSet 
    {
//      UserDefaults.standard.removeObject(
//           forKey: EmojiArtDocument.untitled )

      UserDefaults.standard.set(
                   emojiArt.json, 
           forKey: EmojiArtDocument.untitled )
    }
  }
  
  private static let untitled = "EmojiArtDocument.Untitled"
    
  init() 
  {
    emojiArt = 
      EmojiArt(
          json: UserDefaults.standard.data(
                  forKey: EmojiArtDocument.untitled) ) ?? EmojiArt()

    fetchBackgroundImageData()
  }  // end init
        
  @Published private(set) var backgroundImage: UIImage?
  
  var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
  

            // When one taps on a dropped emoji it will be added to
            // this array.  If it was already in this array then it
            // will be removed.
            
  @Published var selectedEmojis: [EmojiArt.Emoji] = []


  //----------------------------
  // MARK: - Intent(s)
  
  //----------------
  func addEmoji(
             _ emoji: String, 
         at location: CGPoint, 
                size: CGFloat) 
  {
    emojiArt.addEmoji(
                    emoji, 
                 x: Int(location.x), 
                 y: Int(location.y), 
              size: Int(size) )
  }  // end func addEmoji

  
  //----------------
  func moveEmoji(
         _ emoji: EmojiArt.Emoji, 
       by offset: CGSize) 
  {
    if let index = emojiArt.emojis.firstIndex(matching: emoji) 
    {
      emojiArt.emojis[index].x += Int(offset.width)
      emojiArt.emojis[index].y += Int(offset.height)
    }
  }  // end func moveEmoji

  
  //----------------
  func scaleEmoji(
        _ emoji: EmojiArt.Emoji, 
       by scale: CGFloat) 
  {
    if let index = emojiArt.emojis.firstIndex(matching: emoji) 
    {
      emojiArt.emojis[index].size = 
          Int( ( CGFloat(emojiArt.emojis[index].size ) * scale )
          .rounded( .toNearestOrEven ) )
    }
  }  // end func scaleEmoji


  //----------------
  func setBackgroundURL(_ url: URL?) 
  {
    emojiArt.backgroundURL = url?.imageURL
    fetchBackgroundImageData()
  }  // end func setBackgroundURL

  
  //----------------
  private func fetchBackgroundImageData() 
  {
    backgroundImage = nil
    if let url = self.emojiArt.backgroundURL 
    {
      DispatchQueue.global( qos: .userInitiated ).async 
      {
        if let imageData = try? Data( contentsOf: url ) 
        {
          DispatchQueue.main.async 
          {
            if url == self.emojiArt.backgroundURL 
              { self.backgroundImage = UIImage(data: imageData) }
          }  // end DispatchQueue.main
        }  // end if

      }  // end DispatchQueue.global
    }  // end if

  }  // end func fetchBackgroundImageData


  //----------------
  func clearUI()
  {
    emojiArt.emojis = [EmojiArt.Emoji]()
    backgroundImage = nil

    UserDefaults.standard.removeObject(
        forKey: EmojiArtDocument.untitled )
  }  // end func clearUI


  //----------------
  func toggleSelected( tappedEmoji: EmojiArt.Emoji )
  {
    if selectedEmojis.contains( tappedEmoji )
    {
      selectedEmojis = 
          selectedEmojis.filter
            { $0 != tappedEmoji }
    }
    else
    {
      selectedEmojis.append( tappedEmoji )
    }
  }  // end func toggleSelected


  //----------------
  func unSelectAllEmojis()
  {
            // Remove the selected emojis from the selected emoji array

    for tEmoji in selectedEmojis
    {
      selectedEmojis = 
          selectedEmojis.filter
            { $0 != tEmoji }
    }
  }  // end func unSelectAllEmojis


  //----------------
  func emojiSelected( tappedEmoji: EmojiArt.Emoji ) -> Bool
  {
    if selectedEmojis.contains( tappedEmoji )
    { return true }
    else
    { return false }
  }  // end func emojiSelected


  //----------------
  func removeSelectedEmojis()
  {
            // Remove the selected emojis from the model's emoji array

    for tEmoji in selectedEmojis
    {
      emojiArt.removeEmoji( anEmoji: tEmoji )
    }
            // Remove the selected emojis from the selected emoji array

    for tEmoji in selectedEmojis
    {
      selectedEmojis = 
          selectedEmojis.filter
            { $0 != tEmoji }
    }

  }  // end func removeSelectedEmojis



}  // end class EmojiArtDocument


  



//----------------------------
extension EmojiArt.Emoji {
  var fontSize: CGFloat { CGFloat(self.size) }
  var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}
