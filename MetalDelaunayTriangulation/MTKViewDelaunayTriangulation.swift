//
//  MTKViewDelaunayTriangulation.swift
//  MetalDelaunayTriangulation
//
//  Created by vladimir sierra on 5/20/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//


import Metal
import MetalKit

protocol MTKViewDelaunayTriangulationDelegate: NSObjectProtocol{
  
  func fpsUpdate (fps: Int)
}

class MTKViewDelaunayTriangulation: MTKView {
  
  /*

  fileprivate var imageWidthFloatBuffer: MTLBuffer!
  fileprivate var imageHeightFloatBuffer: MTLBuffer!
  
  let bytesPerRow: Int
  let region: MTLRegion
  let blankBitmapRawData : [UInt8]
  
  fileprivate var kernelFunction: MTLFunction!
  fileprivate var pipelineState: MTLComputePipelineState!
  fileprivate var defaultLibrary: MTLLibrary! = nil
  fileprivate var commandQueue: MTLCommandQueue! = nil
  
  fileprivate var errorFlag:Bool = false
  
  fileprivate var threadsPerThreadgroup:MTLSize!
  fileprivate var threadgroupsPerGrid:MTLSize!
  
  let vertexCount: Int
  let alignment:Int = 0x4000
  let verticesMemoryByteSize:Int
  */
  
  var kernelFunction: MTLFunction!
  var pipelineState: MTLComputePipelineState!
  var defaultLibrary: MTLLibrary! = nil
  var commandQueue: MTLCommandQueue! = nil
  var errorFlag:Bool = false
  
  var vertexCount: Int
  var verticesMemoryByteSize:Int
  
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 20))
  var frameNumber = 0
  var frameStartTime = CFAbsoluteTimeGetCurrent()
 
  
  weak var metalViewSpecialDelegate: MetalViewSpecialDelegate?
  
  ////////////////////
  init()

  {

    vertexCount = 1000
    //bytesPerRow = Int(4 * imageWidth)
    
    //region = MTLRegionMake2D(0, 0, Int(imageWidth), Int(imageHeight))
    //blankBitmapRawData = [UInt8](repeating: 0, count: Int(imageWidth * imageHeight * 4))
    verticesMemoryByteSize = vertexCount * MemoryLayout<VertexWithColor>.size


    super.init(frame: UIScreen.main.bounds, device: MTLCreateSystemDefaultDevice())
    
  }
  
  required init(coder aDecoder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }
  ////////////////////
  
  func step() {
    frameNumber += 1
    if frameNumber == 100
    {
      let frametime = (CFAbsoluteTimeGetCurrent() - frameStartTime) / 100
      metalViewSpecialDelegate?.fpsUpdate(fps: Int(1 / frametime))
      //print ("...frametime: \(frametime)")
      frameStartTime = CFAbsoluteTimeGetCurrent()
      frameNumber = 0
    }
  }
  
  func metalSetup(){
    //device = MTLCreateSystemDefaultDevice()
    
    guard let device = MTLCreateSystemDefaultDevice() else
    {
      errorFlag = true
      
      //particleLabDelegate?.particleLabMetalUnavailable()
      
      return
    }
    //mtkView.device = device
    commandQueue = device.makeCommandQueue() // Create a new command queue
    defaultLibrary = device.newDefaultLibrary() // Load the default library
    
    let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
    
    // set up your render pipeline configuration
    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
    renderPipelineDescriptor.vertexFunction = vertexProgram
    /*
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
    */
  }
  
  
  // Only override draw() if you perform custom drawing.
  // An empty implementation adversely affects performance during animation.
  override func draw(_ rect: CGRect) {
    step()
  }

} // end of class MTKViewDelaunayTriangulation
