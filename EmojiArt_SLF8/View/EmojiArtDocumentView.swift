
// ==================== MVVM - VIEW ============================
//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

//----------------------------
struct EmojiArtDocumentView: View 
{
  @ObservedObject var document: EmojiArtDocument
  
  //----------------
  var body: some View 
  {
    VStack 
    {
      HStack
      {
        ScrollView(.horizontal) 
        {
          HStack 
          {
            ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) 
            { emoji in
              Text(emoji)
                .font( Font.system( size: self.defaultEmojiSize ) )
                .onDrag 
                { 
                  NSItemProvider( object: emoji as NSString )
                }
            }  // end ForEach
          }  // end HStack
        }  // end ScrollView
//        .padding(.horizontal)

        Spacer()
        Button(
          action:
          {
            print( "Delete Emoji button pressed" )
            self.document.removeSelectedEmojis()
          }   )
          {
            Text("Delete Emoji")
              .fontWeight(.bold)
              .font(.body)
              .frame(minWidth: 200, maxWidth: 200, minHeight: 40, maxHeight: 40)
              .background(Color.red)
              .cornerRadius(40)
              .foregroundColor(.white)
          }  // end Button
          .padding()

        Button(
          action:
          {
            self.document.clearUI()
            print( "Clear button pressed" )
          }   )
          {
            Text("Clear")
              .fontWeight(.bold)
              .font(.body)
              .frame(minWidth: 200, maxWidth: 200, minHeight: 40, maxHeight: 40)
              .background(Color.red)
              .cornerRadius(40)
              .foregroundColor(.white)
              .frame(minWidth: 200, maxWidth: 200, minHeight: 80, maxHeight: 80)
          }  // end Button

      }  // end HStack	  


      GeometryReader 
      { geometry in
        ZStack 
        {
          Color.white.overlay(
            OptionalImage(uiImage: self.document.backgroundImage)
              .scaleEffect(self.zoomScale)
//              .offset(self.panOffset)
          )
            .gesture(self.doubleTapToZoom(in: geometry.size))
            .onTapGesture
            {
              self.document.unSelectAllEmojis()
            }
          ForEach(self.document.emojis) 
          { emoji in
            Text(emoji.text)
              .font(animatableWithSize: emoji.fontSize * self.zoomScale)
              .background( 
                self.document.emojiSelected( 
                  tappedEmoji: emoji ) ? Color.yellow : Color.clear )
              .cornerRadius( 100 )
              .position(self.position(for: emoji, in: geometry.size))

              .onTapGesture
              {
                print( "Within onTapGesture()" )
                self.document.toggleSelected( tappedEmoji: emoji )
              }

              .gesture(self.panEmojiGesture( anEmoji: emoji ))

          }  // end ForEach
        }  // end ZStack
        .clipped()
//        .gesture(self.panGesture())
//        .gesture(self.zoomGesture())
        .edgesIgnoringSafeArea([.horizontal, .bottom])

        .onDrop( 
                   of: ["public.image","public.text"], 
           isTargeted: nil )
        { providers, location in

          // SwiftUI bug (as of 13.4)? the location is supposed to be
          // in our coordinate system however, the y coordinate
          // appears to be in the global coordinate system

          var location = 
            CGPoint(
              x: location.x, 
              y: geometry.convert(location, from: .global).y )

          location = 
            CGPoint(
              x: location.x - geometry.size.width/2, 
              y: location.y - geometry.size.height/2 )

          location = 
            CGPoint(
              x: location.x - self.panOffset.width, 
              y: location.y - self.panOffset.height )

          location = 
            CGPoint(
              x: location.x / self.zoomScale, 
              y: location.y / self.zoomScale )

          return self.drop(providers: providers, at: location)

        }  // end .onDrop
      }  // end GeometryReader
    }  // end VStack
  }  // end var body

  
  //----------------
  @State private var steadyStateZoomScale: CGFloat = 1.0

  @GestureState private var gestureZoomScale: CGFloat = 1.0
  
  private var zoomScale: CGFloat 
  {
    steadyStateZoomScale * gestureZoomScale
  }
  

  //----------------
  private func zoomGesture() -> some Gesture 
  {
    MagnificationGesture()
      .updating( $gestureZoomScale )
      { latestGestureScale, gestureZoomScale, transaction in
        gestureZoomScale = latestGestureScale
      }
      .onEnded 
      { finalGestureScale in
        self.steadyStateZoomScale *= finalGestureScale
      }
  }  // end func zoomGesture
  

  //----------------
  private func zoomEmojiGesture() -> some Gesture 
  {
    MagnificationGesture()
      .updating( $gestureZoomScale )
      { latestGestureScale, gestureZoomScale, transaction in
        gestureZoomScale = latestGestureScale
      }
      .onEnded 
      { finalGestureScale in
        self.steadyStateZoomScale *= finalGestureScale
      }
  }  // end func zoomEmojiGesture
  

  @State private var steadyStatePanOffset: CGSize = .zero
  @GestureState private var gesturePanOffset: CGSize = .zero
  
  @State private var selectedSteadyStatePanOffset: CGSize = .zero
  @GestureState private var selectedGesturePanOffset: CGSize = .zero

  //----------------
  private var panOffset: CGSize 
  {
    (steadyStatePanOffset + gesturePanOffset) * zoomScale
  }

  //----------------
  private var selectedPanOffset: CGSize 
  {
    (selectedSteadyStatePanOffset + selectedGesturePanOffset) * zoomScale
  }


  //----------------
  private func panGesture() -> some Gesture 
  {
    DragGesture()
      .updating($gesturePanOffset) 
      { latestDragGestureValue, gesturePanOffset, transaction in
        gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
      }
      .onEnded 
      { finalDragGestureValue in
        self.steadyStatePanOffset = 
          self.steadyStatePanOffset + 
            ( finalDragGestureValue.translation / self.zoomScale )
      }
  }  // end panGesture

  
  //----------------
  private func panEmojiGesture( anEmoji: EmojiArt.Emoji ) -> some Gesture 
  {
    DragGesture()
      .updating($selectedGesturePanOffset) 
      { latestDragGestureValue, selectedGesturePanOffset, transaction in
        print( "Within panEmojiGesture()" )
        if self.document.emojiSelected( tappedEmoji: anEmoji )
        {
          selectedGesturePanOffset = 
            latestDragGestureValue.translation / self.zoomScale
        }
      }
      .onEnded 
      { finalDragGestureValue in
        if self.document.emojiSelected( tappedEmoji: anEmoji )
        {
          self.selectedSteadyStatePanOffset = 
            self.selectedSteadyStatePanOffset + 
              ( finalDragGestureValue.translation / self.zoomScale )

          self.document.moveEmoji( 
                  anEmoji, by: self.selectedSteadyStatePanOffset )
          self.selectedSteadyStatePanOffset = .zero

        }
      }
  }  // end panEmojiGesture

  
  //----------------
  private func doubleTapToZoom( in size: CGSize ) -> some Gesture 
  {
    TapGesture( count: 2 )
      .onEnded 
      {
        withAnimation 
        {
          self.zoomToFit(self.document.backgroundImage, in: size)
        }
      }
  }  // end func doubleTapToZoom
  

  //----------------
  private func zoomToFit(
               _ image: UIImage?, 
               in size: CGSize )
  {
    if let image = image, image.size.width > 0, image.size.height > 0 
    {
      let hZoom = size.width / image.size.width
      let vZoom = size.height / image.size.height
      self.steadyStatePanOffset = .zero
      self.steadyStateZoomScale = min(hZoom, vZoom)
    }
  }  // end func zoomToFit

    
  //----------------
  private func position(
               for emoji: EmojiArt.Emoji, 
                 in size: CGSize)
          -> CGPoint
  {
    var location = emoji.location

    location = CGPoint(
                 x: location.x * zoomScale, 
                 y: location.y * zoomScale )

    location = CGPoint(
                 x: location.x + size.width/2, 
                 y: location.y + size.height/2 )

    if self.document.emojiSelected( tappedEmoji: emoji )
    {
      location = CGPoint(
                   x: location.x + selectedPanOffset.width, 
                   y: location.y + selectedPanOffset.height )
    }
//    else
//    {
//      location = CGPoint(
//                   x: location.x + panOffset.width, 
//                   y: location.y + panOffset.height )
//    }

    return location
  }  // end func position
  
  
  //----------------
  private func drop(
                 providers: [NSItemProvider], 
               at location: CGPoint )
          -> Bool 
  {
    var found = providers.loadFirstObject(ofType: URL.self) 
    { url in
      self.document.setBackgroundURL(url)
    }
    if !found 
    {
      found = providers.loadObjects(ofType: String.self) 
      { string in
        self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
      }
    }
    return found
  }  // end func drop
  

  //----------------
  private let defaultEmojiSize: CGFloat = 40

}  // end struct EmojiArtDocumentView
