//
//  MetalViewSpecial.swift
//  MetalDelaunayTriangulation
//
//  Created by vladimir sierra on 5/19/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//


import Metal
import MetalKit

protocol MetalViewSpecialDelegate: NSObjectProtocol{
  
  func fpsUpdate (fps: Int)
}

class MetalViewSpecial: MTKView {
  
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 20))
  var frameNumber = 0
  var frameStartTime = CFAbsoluteTimeGetCurrent()
  
  weak var metalViewSpecialDelegate: MetalViewSpecialDelegate?
  

  

  
  func step() {
    //frameStartTime = CFAbsoluteTimeGetCurrent()
    frameNumber += 1
    
    if frameNumber == 100
    {
      let frametime = (CFAbsoluteTimeGetCurrent() - frameStartTime) / 100
      metalViewSpecialDelegate?.fpsUpdate(fps: Int(1 / frametime))
      //let description = "fps: \(Int(1 / frametime))"
      //self.fpsLabel.text = description
      print ("...frametime: \(frametime)")
      frameStartTime = CFAbsoluteTimeGetCurrent()
      frameNumber = 0
    }
  }

  
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        step()
    }
 

}


