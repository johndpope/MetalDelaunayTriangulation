//
//  MTKViewDelaunayTriangulation.swift
//  MetalDelaunayTriangulation
//
//  Created by vladimir sierra on 5/20/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//


import Metal
import MetalKit
import GameplayKit

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
  var verticesArray: [Vertex]!
  //var vertexCount: Int
  //var verticesMemoryByteSize:Int
  
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 20))
  var frameCounter: Int = 0
  var frameStartTime = CFAbsoluteTimeGetCurrent()
 
  
  weak var MTKViewDelaunayTriangulationDelegate: MTKViewDelaunayTriangulationDelegate?
  
  ////////////////////
  init(frame: CGRect) {

    //vertexCount = 100
    //verticesMemoryByteSize = vertexCount * MemoryLayout<VertexWithColor>.size
    //verticesMemoryByteSize = vertexCount * MemoryLayout<VertexWithColor>.stride // apple recommendation
    super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
    
    setupBackground()
    setupMetal()
    
    //setupTriangles()
    //renderTriangles()
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  override func draw(_ rect: CGRect) {
    
    step() // needed to update frame counter
    
    autoreleasepool {
      //setupTriangles()
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
      print ("...frametime: \((Int(1/frametime)))")
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
  
  /// Generate set of vertices for our delaunay triangulation to use
  func generateVertices(_ size: CGSize, cellSize: CGFloat, variance: CGFloat = 0.75, seed: UInt64 = numericCast(arc4random())) -> [Vertex] {
    
    // How many cells we're going to have on each axis (pad by 2 cells on each edge)
    let cellsX = (size.width + 4 * cellSize) / cellSize
    let cellsY = (size.height + 4 * cellSize) / cellSize
    
    // figure out the bleed widths to center the grid
    let bleedX = ((cellsX * cellSize) - size.width)/2
    let bleedY = ((cellsY * cellSize) - size.height)/2
    
    let _variance = cellSize * variance / 4
    
    var points = [Vertex]()
    let minX = -bleedX
    let maxX = size.width + bleedX
    let minY = -bleedY
    let maxY = size.height + bleedY
    
    let generator = GKLinearCongruentialRandomSource(seed: seed)
    
    for i in stride(from: minX, to: maxX, by: cellSize) {
      for j in stride(from: minY, to: maxY, by: cellSize) {
        
        let x = i + cellSize/2 + CGFloat(generator.nextUniform()) + CGFloat.random(-_variance, _variance)
        let y = j + cellSize/2 + CGFloat(generator.nextUniform()) + CGFloat.random(-_variance, _variance)
        
        points.append(Vertex(x: Double(x), y: Double(y)))
      }
    }
    
    return points
  } // end of generateVertices
  
  func setupBackground () {
    // set up initial bg triangles
    verticesArray = [] // empty out simple vertex array
    verticesWithColorArray = [] // empty out vertex array
    
    /*
    // create vertices for view's corners
    let v0 = VertexWithColor(x: -1.0, y:   1.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0) // ul
    let v1 = VertexWithColor(x:  1.0, y:   1.0, z:   0.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0) // ur
    let v2 = VertexWithColor(x: -1.0, y:  -1.0, z:   0.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0) // ll
    let v3 = VertexWithColor(x:  1.0, y:  -1.0, z:   0.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0) // lr
    
    
    
    // add vertices to create bg upper triangle
    verticesWithColorArray.append(v0)
    verticesWithColorArray.append(v1)
    verticesWithColorArray.append(v2)
    // add vertices to create bg lower triangle
    verticesWithColorArray.append(v2)
    verticesWithColorArray.append(v3)
    verticesWithColorArray.append(v1)
    */
    
    let vv0 = Vertex(x: 0.0, y:   0.0) // ul
    let vv1 = Vertex(x: Double(self.bounds.size.width), y: 0.0) // ur
    let vv2 = Vertex(x: 0.0, y: Double(self.bounds.size.height)) // ll
    let vv3 = Vertex(x: Double(self.bounds.size.width), y: Double(self.bounds.size.height)) // lr
    
    verticesArray.append(vv0)
    verticesArray.append(vv2)
    verticesArray.append(vv1)
    
    verticesArray.append(vv1)
    verticesArray.append(vv2)
    verticesArray.append(vv3)
    
    delaunayCompute()
 
    
  } // end of func setupBackground
  
  func vertexAppend (point: CGPoint) {
    //let x = Float(point.x)/Float(self.bounds.size.width)*2.0 - 1.0
    //let y = 1.0 - Float(point.y)/Float(self.bounds.size.height)*2.0
    //let v = VertexWithColor(x: x, y: y, z: 0.0, r: Float(Double.random()), g: Float(Double.random()), b: Float(Double.random()), a: 0.0)
    //verticesWithColorArray.append(v)
    
    //let x = Double(point.x)/Double(self.bounds.size.width)*2.0 - 1.0
    //let y = 1.0 - Double(point.y)/Double(self.bounds.size.height)*2.0
    let x = Double(point.x)
    let y = Double(point.y)
    let v = Vertex(x: x, y: y)
    verticesArray.append(v)
    
    print ("...vertex count: \(verticesArray.count)")
    
    
  } // end of func vertexAppend
  
  func delaunayCompute () {
    verticesWithColorArray = [] // empty out vertex array
    
    
    
    //let vertexCount = verticesArray.count
    //if vertexCount % 3 == 0 {
      let triangles = Delaunay().triangulate(verticesArray)
      print ("......triangle count: \(triangles.count)")
      for triangle in triangles {
        // convert triangle vertices from device units to metal units
        let x1 = Float(triangle.vertex1.x)/Float(self.bounds.size.width)*2.0 - 1.0
        let x2 = Float(triangle.vertex2.x)/Float(self.bounds.size.width)*2.0 - 1.0
        let x3 = Float(triangle.vertex3.x)/Float(self.bounds.size.width)*2.0 - 1.0
        
        let y1 = 1.0 - Float(triangle.vertex1.y)/Float(self.bounds.size.height)*2.0
        let y2 = 1.0 - Float(triangle.vertex2.y)/Float(self.bounds.size.height)*2.0
        let y3 = 1.0 - Float(triangle.vertex3.y)/Float(self.bounds.size.height)*2.0
        
        let v1 = VertexWithColor(x: x1, y: y1, z: 0.0, r: 1.0, g: 0.0, b: 0.0, a: 0.0)
        let v2 = VertexWithColor(x: x2, y: y2, z: 0.0, r: 0.0, g: 1.0, b: 0.0, a: 0.0)
        let v3 = VertexWithColor(x: x3, y: y3, z: 0.0, r: 0.0, g: 0.0, b: 1.0, a: 0.0)
        
        verticesWithColorArray.append(v1)
        verticesWithColorArray.append(v2)
        verticesWithColorArray.append(v3)
        
        
      } // end of for triangles
      //vertexCount = verticesWithColorArray.count
      print ("...... debug vsimple = \(verticesArray.count) vcolor = \(verticesWithColorArray.count)")
    //} // end of if
    
  }
  
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
    for _ in 0 ... 300 {
      //for vertex in vertices {
      let x = Float(Double.random(-1.0, 1.0))
      let y = Float(Double.random(-1.0, 1.0))
      let v = VertexWithColor(x: x, y: y, z: 0.0, r: Float(Double.random()), g: Float(Double.random()), b: Float(Double.random()), a: 0.0)
      
      verticesWithColorArray.append(v)
    } // end of for _ in
    
 
    
    /*
    // create n deulanay triangles
    ///////////////////
    let vertices = generateVertices(self.bounds.size, cellSize: 100)
    let triangles = Delaunay().triangulate(vertices)
    verticesWithColorArray = [] // empty out vertex array
    
    for triangle in triangles {
      // convert triangle vertices from device units to metal units
      let x1 = Float(triangle.vertex1.x)/Float(self.bounds.size.width)*2.0 - 1.0
      let x2 = Float(triangle.vertex2.x)/Float(self.bounds.size.width)*2.0 - 1.0
      let x3 = Float(triangle.vertex3.x)/Float(self.bounds.size.width)*2.0 - 1.0
      
      let y1 = Float(triangle.vertex1.y)/Float(self.bounds.size.height)*2.0 - 1.0
      let y2 = Float(triangle.vertex2.y)/Float(self.bounds.size.height)*2.0 - 1.0
      let y3 = Float(triangle.vertex3.y)/Float(self.bounds.size.height)*2.0 - 1.0
      
      let v1 = VertexWithColor(x: x1, y: y1, z: 0.0, r: 1.0, g: 0.0, b: 0.0, a: 0.0)
      let v2 = VertexWithColor(x: x2, y: y2, z: 0.0, r: 0.0, g: 1.0, b: 0.0, a: 0.0)
      let v3 = VertexWithColor(x: x3, y: y3, z: 0.0, r: 0.0, g: 0.0, b: 1.0, a: 0.0)
      
      verticesWithColorArray.append(v1)
      verticesWithColorArray.append(v2)
      verticesWithColorArray.append(v3)
    } // end of for triangles
    vertexCount = verticesWithColorArray.count
    */
 
    
  } // end of setupTriangles
  
  func renderTriangles(){
    // 6. Set buffer size of objects to be drawn
    //let dataSize = vertexCount * MemoryLayout<VertexWithColor>.size // size of the vertex data in bytes
    let dataSize = verticesWithColorArray.count * MemoryLayout<VertexWithColor>.stride // apple recommendation
    let vertexBuffer: MTLBuffer = device!.makeBuffer(bytes: verticesWithColorArray, length: dataSize, options: []) // create a new buffer on the GPU
    let renderPassDescriptor: MTLRenderPassDescriptor? = self.currentRenderPassDescriptor
    //if verticesWithColorArray.count % 3 == 0 {
      // If the renderPassDescriptor is valid, begin the commands to render into its drawable
      if renderPassDescriptor != nil {
        // Create a new command buffer for each tessellation pass
        
        let commandBuffer: MTLCommandBuffer? = commandQueue.makeCommandBuffer()
        // Create a render command encoder
        // 7a. Create a renderCommandEncoder four our renderPipeline
        let renderCommandEncoder: MTLRenderCommandEncoder? = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
        renderCommandEncoder?.label = "Render Command Encoder"
        renderCommandEncoder?.setTriangleFillMode(.lines)
        //////////renderCommandEncoder?.pushDebugGroup("Tessellate and Render")
        renderCommandEncoder?.setRenderPipelineState(renderPipeline!)
        renderCommandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        // most important below: we tell the GPU to draw a set of triangles, based on the vertex buffer. Each triangle consists of three vertices, starting at index 0 inside the vertex buffer, and there are vertexCount/3 triangles total
        //renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
        renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesWithColorArray.count)
        
        ///////////renderCommandEncoder?.popDebugGroup()
        renderCommandEncoder?.endEncoding() // finalize renderEncoder set up
        
        commandBuffer?.present(self.currentDrawable!) // needed to make sure the new texture is presented as soon as the drawing completes
        
        // 7b. Render to pipeline
        commandBuffer?.commit() // commit and send task to gpu
        
      } // end of if renderPassDescriptor
      
    //} // end of if
    
  }// end of func renderTriangles()
  

} // end of class MTKViewDelaunayTriangulation
