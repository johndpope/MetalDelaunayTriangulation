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
  
  //var kernelFunction: MTLFunction!
  var pipelineState: MTLComputePipelineState!
  var defaultLibrary: MTLLibrary! = nil
  var commandQueue: MTLCommandQueue! = nil
  var renderPipeline: MTLRenderPipelineState!
  var errorFlag:Bool = false
  
  var verticesWithColorArray : [VertexWithColor]!
  var vertexCount: Int
  var verticesMemoryByteSize:Int
  
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 20))
  var frameCounter: Int = 0
  var frameStartTime = CFAbsoluteTimeGetCurrent()
 
  
  weak var MTKViewDelaunayTriangulationDelegate: MTKViewDelaunayTriangulationDelegate?
  
  ////////////////////
  init(frame: CGRect) {

    vertexCount = 100
    verticesMemoryByteSize = vertexCount * MemoryLayout<VertexWithColor>.size

    super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
    
    setupMetal()
    setupTriangles()
    renderTriangles()
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  /*
  override func draw() {
    step() // needed to update frame counter
    
    setupTriangles()
    renderTriangles()
  }*/
  
  override func draw(_ rect: CGRect) {
    
    step() // needed to update frame counter
    autoreleasepool {
      setupTriangles()
      renderTriangles()
    }
  }
  

  
  
  ////////////////////
  
  func step() {
    frameCounter += 1
    if frameCounter == 100
    {
      let frametime = (CFAbsoluteTimeGetCurrent() - frameStartTime) / 100
      MTKViewDelaunayTriangulationDelegate?.fpsUpdate(fps: Int(1 / frametime)) // let the delegate know of the frame update
      //print ("...frametime: \(frametime)")
      frameStartTime = CFAbsoluteTimeGetCurrent() // reset start time
      frameCounter = 0 // reset counter
    }
  }
  
  func setupMetal(){
    
    // Steps required to set up metal for rendering:
    
    // 1. Create a MTLDevice
    // 2. Create a Command Queue
    // 3. Access the custom shader library
    // 4. Compile shaders from library
    // 5. Create a render pipeline
    // 6. Set buffer size of objects to be drawn
    // 7. Draw to pipeline through a renderCommandEncoder
    

    // 1. Create a MTLDevice
    guard let device = MTLCreateSystemDefaultDevice() else {
      errorFlag = true
      //particleLabDelegate?.particleLabMetalUnavailable()
      return
    }
    
    // 2. Create a Command Queue
    commandQueue = device.makeCommandQueue()
    
    // 3. Access the custom shader library
    defaultLibrary = device.newDefaultLibrary()
    
    // 4. Compile shaders from library
    let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
    
    // 5a. Define render pipeline settings
    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
    renderPipelineDescriptor.vertexFunction = vertexProgram
    renderPipelineDescriptor.sampleCount = self.sampleCount
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
    renderPipelineDescriptor.fragmentFunction = fragmentProgram
 
    // 5b. Compile renderPipeline with above renderPipelineDescriptor
    do {
      renderPipeline = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    } catch let error as NSError {
      print("render pipeline error: " + error.description)
    }
    
    // initialize counter variables
    frameStartTime = CFAbsoluteTimeGetCurrent()
    frameCounter = 0

  } // end of setupMetal
  
  func setupTriangles(){
    /*
     // create a single triangle
     ///////////////////
     let V0 = VertexWithColor(x:  0.0, y:   1.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
     let V1 = VertexWithColor(x: -1.0, y:  -1.0, z:   0.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
     let V2 = VertexWithColor(x:  1.0, y:  -1.0, z:   0.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
     
     let verticesWithColorArray = [V0,V1,V2]
     let vertexCount = verticesWithColorArray.count
     */
    
    // generate n random triangles
    ///////////////////
    verticesWithColorArray = [] // empty out vertex array
    for _ in 0 ... vertexCount {
      //for vertex in vertices {
      let x = Float(Double.random(-1.0, 1.0))
      let y = Float(Double.random(-1.0, 1.0))
      let v = VertexWithColor(x: x, y: y, z: 0.0, r: Float(Double.random()), g: Float(Double.random()), b: Float(Double.random()), a: 0.0)
      
      verticesWithColorArray.append(v)
    }
    
    /*
     // create n deulanay triangles
     ///////////////////
     let vertices = generateVertices(mtkView.bounds.size, cellSize: 100)
     let triangles = Delaunay().triangulate(vertices)
     var verticesWithColorArray = [VertexWithColor]()
     
     for triangle in triangles {
     // convert triangle vertices from device units to metal units
     let x1 = Float(triangle.vertex1.x)/Float(mtkView.bounds.size.width)*2.0 - 1.0
     let x2 = Float(triangle.vertex2.x)/Float(mtkView.bounds.size.width)*2.0 - 1.0
     let x3 = Float(triangle.vertex3.x)/Float(mtkView.bounds.size.width)*2.0 - 1.0
     
     let y1 = Float(triangle.vertex1.y)/Float(mtkView.bounds.size.height)*2.0 - 1.0
     let y2 = Float(triangle.vertex2.y)/Float(mtkView.bounds.size.height)*2.0 - 1.0
     let y3 = Float(triangle.vertex3.y)/Float(mtkView.bounds.size.height)*2.0 - 1.0
     
     let v1 = VertexWithColor(x: x1, y: y1, z: 0.0, r: 1.0, g: 0.0, b: 0.0, a: 0.0)
     let v2 = VertexWithColor(x: x2, y: y2, z: 0.0, r: 0.0, g: 1.0, b: 0.0, a: 0.0)
     let v3 = VertexWithColor(x: x3, y: y3, z: 0.0, r: 0.0, g: 0.0, b: 1.0, a: 0.0)
     
     verticesWithColorArray.append(v1)
     verticesWithColorArray.append(v2)
     verticesWithColorArray.append(v3)
     }
     */
    
  } // end of setupTriangles
  
  func renderTriangles(){
    // 6. Set buffer size of objects to be drawn
    let dataSize = vertexCount * MemoryLayout<VertexWithColor>.size // size of the vertex data in bytes
    let vertexBuffer: MTLBuffer = device!.makeBuffer(bytes: verticesWithColorArray, length: dataSize, options: []) // create a new buffer on the GPU
    let renderPassDescriptor: MTLRenderPassDescriptor? = self.currentRenderPassDescriptor
    
    // If the renderPassDescriptor is valid, begin the commands to render into its drawable
    if renderPassDescriptor != nil {
      // Create a new command buffer for each tessellation pass
      
      let commandBuffer: MTLCommandBuffer? = commandQueue.makeCommandBuffer()
      // Create a render command encoder
      // 7a. Create a renderCommandEncoder four our renderPipeline
      let renderCommandEncoder: MTLRenderCommandEncoder? = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
      renderCommandEncoder?.label = "Render Command Encoder"
      //////////renderCommandEncoder?.pushDebugGroup("Tessellate and Render")
      renderCommandEncoder?.setRenderPipelineState(renderPipeline!)
      renderCommandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
      // most important below: we tell the GPU to draw a set of triangles, based on the vertex buffer. Each triangle consists of three vertices, starting at index 0 inside the vertex buffer, and there are vertexCount/3 triangles total
      renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
      
      ///////////renderCommandEncoder?.popDebugGroup()
      renderCommandEncoder?.endEncoding() // finalize renderEncoder set up
      
      commandBuffer?.present(self.currentDrawable!) // needed to make sure the new texture is presented as soon as the drawing completes
      
      // 7b. Render to pipeline
      commandBuffer?.commit() // commit and send task to gpu
      
    } // end of if renderPassDescriptor 
    
  }// end of func renderTriangles()
  

} // end of class MTKViewDelaunayTriangulation
