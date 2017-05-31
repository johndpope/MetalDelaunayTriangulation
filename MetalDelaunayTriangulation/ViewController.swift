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
    
    delaunayView.enableSetNeedsDisplay = true // needed so we can call setNeedsDisplay() locally to force a display update
    delaunayView.isPaused = true  // may not be needed, as the enableSetNeedsDisplay flag above seems to pause screen activity upon start anyway
    
    view.addSubview(delaunayView)
    
    fpsLabel.textColor = UIColor.yellow
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
      let triangle: Triangle = delaunayView.delaunayFindTriangleForPoint(p: touchPoint)
      
      /*
      delaunayView.vertexAppend(point: touchPoint)
      delaunayView.delaunayCompute()
      delaunayView.setNeedsDisplay()
      */
      
    } // end of if let touch
  } // end of func touchesBegan()
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first  {
      let touchPoint = touch.location(in: view)
      //delaunayView.delaunayFindTriangleForPoint(p: touchPoint)
      //print ("...touch \(touchPoint)")
      /*
      delaunayView.vertexAppend(point: touchPoint)      
      delaunayView.delaunayCompute()
      delaunayView.setNeedsDisplay()
      */
      
    } // end if if let touch
  } // end of func touchesMoved()
 
  
  
  func fpsUpdate(fps: Int, triangleCount: Int) {
    let description = "fps: \(Int(fps)), triangles: \(triangleCount))"
    
    DispatchQueue.main.async
      {
        //print ("...updating time: \(description)")
        self.fpsLabel.text = description
    }
    
  }
  
}
