//
//  ViewController.swift
//  MetalDelaunayTriangulation
//
//  Created by vladimir sierra on 5/23/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MTKViewDelaunayTriangulationDelegate {
  
  var delaunayView: MTKViewDelaunayTriangulation!
  
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 20, width: 400, height: 20))
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    
    delaunayView = MTKViewDelaunayTriangulation(frame: UIScreen.main.bounds)
    delaunayView.MTKViewDelaunayTriangulationDelegate = self
    view.addSubview(delaunayView)
    
    fpsLabel.textColor = UIColor.red
    view.addSubview(fpsLabel)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewDidLayoutSubviews()
  {

    delaunayView.frame = view.bounds
    
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first  {
      let touchPoint = touch.location(in: view)
      print ("...touch \(touchPoint)")
      
      autoreleasepool {
        delaunayView.setupTriangles()
        delaunayView.renderTriangles()
      }
    }
  }
  
  
  func fpsUpdate(fps: Int) {
    let description = "fps: \(Int(fps))"
    
    DispatchQueue.main.async
      {
        //print ("...updating time: \(description)")
        self.fpsLabel.text = description
    }
    
  }
  
}
