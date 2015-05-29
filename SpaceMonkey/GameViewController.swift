//
//  GameViewController.swift
//  SpaceMonkey
//
//  Created by Main Account on 4/10/15.
//  Copyright (c) 2015 WangZhuo All rights reserved.
//

import UIKit
import SpriteKit
 
import AVFoundation
 
class GameViewController: UIViewController {
 var backgroundMusicPlayer: AVAudioPlayer!
  override func viewWillLayoutSubviews() {
    super.viewDidLoad()
 
    let skView = self.view as! SKView
    if skView.scene == nil {
 
      let scene = GameScene(size:skView.frame.size)
      skView.showsFPS = true
      skView.showsNodeCount = true
      skView.showsPhysics = true
      skView.ignoresSiblingOrder = true
      scene.scaleMode = .AspectFill
      skView.presentScene(scene)
        playBackgroundMusic("BackgroundMusic.mp3")  
    }
  }
    func playBackgroundMusic(filename: String) {
        let url = NSBundle.mainBundle().URLForResource(
            filename, withExtension: nil)
        if (url == nil) {
            println("Could not find file: \(filename)")
            return
        }
        
        var error: NSError? = nil
        backgroundMusicPlayer =
            AVAudioPlayer(contentsOfURL: url, error: &error)
        if backgroundMusicPlayer == nil {
            println("Could not create audio player: \(error!)")
            return
        }
        
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.prepareToPlay()  
        backgroundMusicPlayer.play()  
    }
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
}