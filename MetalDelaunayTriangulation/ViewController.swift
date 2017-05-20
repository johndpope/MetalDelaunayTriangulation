//
//  ViewController.swift
//  MetalDelaunayTriangulation
//
//  Created by vladimir sierra on 5/19/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//

import UIKit
//import Metal
import MetalKit


class ViewController: UIViewController, MetalViewSpecialDelegate {
  

  @IBOutlet weak var mtkView: MetalViewSpecial! {
    didSet {
      //mtkView.delegate = self
      mtkView.preferredFramesPerSecond = 60
      mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
  }
  
  //weak var ViewControllerDelegate:ViewControllerDelegate?
  
  
  // Seven steps required to set up metal for rendering:
  
  // 1. Create a MTLDevice
  // 2. Create a CAMetalLayer   ???
  // 3. Create a Vertex Buffer
  
  // 4. Create a Vertex Shader
  // 5. Create a Fragment Shader
  
  // 6. Create a Render Pipeline
  // 7. Create a Command Queue
  
  var device: MTLDevice! // to be initialized in viewDidLoad
  //var metalLayer: CAMetalLayer! // to be initialized in viewDidLoad
  var vertexBuffer: MTLBuffer! // to be initialized in viewDidLoad
  
  // once we create a vertex and fragment shader (in the file Shaders.metal), we combine them in an object called render pipeline. In Metal the shaders are precompiled, and the render pipeline configuration is compiled after you first set it up. This makes everything extremely efficient
  
  var renderPipeline: MTLRenderPipelineState! // to be initialized in viewDidLoad
  var commandQueue: MTLCommandQueue! // to be initialized in viewDidLoad.  stores an ordered list of commands forthe GPU to execute
  
  var library: MTLLibrary! // to be initialized in viewDidLoad
  
  var controlPointsBufferTriangle: MTLBuffer?
  
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 20))
  //var frameNumber = 0
  //var frameStartTime : CFAbsoluteTime!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    
    fpsLabel.textColor = UIColor.white
    view.addSubview(fpsLabel)
    
    
    mtkView.metalViewSpecialDelegate = self 
    
    //mtkView.isPaused = true
    //mtkView.enableSetNeedsDisplay = true
    //mtkView.sampleCount = 1 // no antialiasing
    //mtkView.sampleCount = 4 //antialiasing
    mtkView.depthStencilPixelFormat = .invalid  // without this we get: render pipeline's pixelFormat (MTLPixelFormatInvalid) does not match the framebuffer's pixelFormat 
    
    
    device = MTLCreateSystemDefaultDevice()!
    mtkView.device = device
    commandQueue = device.makeCommandQueue() // Create a new command queue
    library = device.newDefaultLibrary()! // Load the default library
    
    let fragmentProgram = library.makeFunction(name: "basic_fragment")
    let vertexProgram = library.makeFunction(name: "basic_vertex")

    // set up your render pipeline configuration
    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
    renderPipelineDescriptor.vertexFunction = vertexProgram
    print ("...metal's default sampling: \(mtkView.sampleCount)")
    renderPipelineDescriptor.sampleCount = mtkView.sampleCount
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
    renderPipelineDescriptor.fragmentFunction = fragmentProgram

    // Compile renderPipeline for triangle-based tessellation
    do {
      renderPipeline = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    } catch let error as NSError {
      print("render pipeline error: " + error.description)
    }
    
    // set up buffers
    ///////////////////
    let V0 = VertexWithColor(x:  0.0, y:   1.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
    let V1 = VertexWithColor(x: -1.0, y:  -1.0, z:   0.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
    let V2 = VertexWithColor(x:  1.0, y:  -1.0, z:   0.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
    
    let verticesArray = [V0,V1,V2]
    let vertexCount = verticesArray.count
    let dataSize = vertexCount * MemoryLayout.size(ofValue: verticesArray[0]) // size of the vertex data in bytes
    vertexBuffer = device.makeBuffer(bytes: verticesArray, length: dataSize, options: []) // create a new buffer on the GPU

    
    let renderPassDescriptor: MTLRenderPassDescriptor? = mtkView.currentRenderPassDescriptor
    
    // If the renderPassDescriptor is valid, begin the commands to render into its drawable
    if renderPassDescriptor != nil {
      // Create a new command buffer for each tessellation pass
      
      let commandBuffer: MTLCommandBuffer? = commandQueue.makeCommandBuffer()
      // Create a render command encoder
      let renderCommandEncoder: MTLRenderCommandEncoder? = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
      renderCommandEncoder?.label = "Render Command Encoder"
      renderCommandEncoder?.setRenderPipelineState(renderPipeline!)
      renderCommandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
      // most important below: we tell the GPU to draw a set of triangles, based on the vertex buffer. Each triangle consists of three vertices, starting at index 0 inside the vertex buffer, and there are vertexCount triangles total
      renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
      renderCommandEncoder?.endEncoding() // finalize renderEncoder set up
      
      commandBuffer?.present(mtkView.currentDrawable!) // needed to make sure the new texture is presented as soon as the drawing completes
      commandBuffer?.commit() // commit and send task to gpu
    }
    


  }
  

  override func viewDidAppear(_ animated: Bool) {
    
    //mtkView.draw()
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  /*
  func step() {
    frameNumber += 1
    
    if frameNumber == 100
    {
      let frametime = (CFAbsoluteTimeGetCurrent() - frameStartTime) / 100
      let description = "fps: \(Int(1 / frametime))"
      self.fpsLabel.text = description
      frameStartTime = CFAbsoluteTimeGetCurrent()
      frameNumber = 0
    }
  } */
  
  func fpsUpdate(fps: Int) {
    let description = "fps: \(Int(fps))"
    
    DispatchQueue.main.async
      {
        self.fpsLabel.text = description
    }
 
  }
  
  
  
  

}


