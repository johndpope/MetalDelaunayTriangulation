//
//  MTKViewDelaunayTriangulation.swift
//  MetalDelaunayTriangulation
//
//  Created by vladimir sierra on 5/20/17.
//  Copyright © 2017 vladimir sierra. All rights reserved.
//


//import Metal
import MetalKit
//import GameplayKit

protocol MTKViewDelaunayTriangulationDelegate: NSObjectProtocol{
  func fpsUpdate (fps: Int, triangleCount: Int)
}

class MTKViewDelaunayTriangulation: MTKView {
  
  var pipelineState: MTLComputePipelineState!
  var defaultLibrary: MTLLibrary! = nil
  var commandQueue: MTLCommandQueue! = nil
  var renderPipeline: MTLRenderPipelineState!
  var errorFlag:Bool = false
  
  var vertexCloud3DColor : [Vertex3DColor]!
  var vertexCloud2D: [Vertex2DSimple]!
  var triangleCount: Int = 0
  //var vertexCount: Int
  //var verticesMemoryByteSize:Int
  
  let fpsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 20))
  var frameCounter: Int = 0
  var frameStartTime = CFAbsoluteTimeGetCurrent()
  
  
  weak var MTKViewDelaunayTriangulationDelegate: MTKViewDelaunayTriangulationDelegate?
  
  ////////////////////
  init(frame: CGRect) {

    super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
    
    setupBackground()
    setupMetal()

  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  override func draw(_ rect: CGRect) {
    
    step() // needed to update frame counter
    autoreleasepool {
      // if we want to generate triangles via the view's internal timer, we want to 
      // call a generation routine (such as setupTrianglesRandom() AND, we must take care
      // to set the view's .enableSetNeedsDisplay = true  and .isPaused = true
      //setupTrianglesRandom(numTriangles: 10000)
      setupTrianglesDelaunay(vertexCount: 10000)
      
      // regardless of whether we are updating manually via user event (such as touchesBegan)
      // or we use the view's internal timer, we must always update state via renderTriangles()
      renderTriangles()
    }
    
  }
  
  
  
  
  ////////////////////
  
  func step() {
    frameCounter += 1
    if frameCounter == 100
    {
      let frametime = (CFAbsoluteTimeGetCurrent() - frameStartTime) / 100
      MTKViewDelaunayTriangulationDelegate?.fpsUpdate(fps: Int(1 / frametime), triangleCount: triangleCount) // let the delegate know of the frame update
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
  
  /*
  /// Generate set of vertices for our delaunay triangulation to use
  func generateVertices(_ size: CGSize, cellSize: CGFloat, variance: CGFloat = 0.75, seed: UInt64 = numericCast(arc4random())) -> [Vertex2DSimple] {
    
    // How many cells we're going to have on each axis (pad by 2 cells on each edge)
    let cellsX = (size.width + 4 * cellSize) / cellSize
    let cellsY = (size.height + 4 * cellSize) / cellSize
    
    // figure out the bleed widths to center the grid
    let bleedX = ((cellsX * cellSize) - size.width)/2
    let bleedY = ((cellsY * cellSize) - size.height)/2
    
    let _variance = cellSize * variance / 4
    
    var points = [Vertex2DSimple]()
    let minX = -bleedX
    let maxX = size.width + bleedX
    let minY = -bleedY
    let maxY = size.height + bleedY
    
    let generator = GKLinearCongruentialRandomSource(seed: seed)
    
    for i in stride(from: minX, to: maxX, by: cellSize) {
      for j in stride(from: minY, to: maxY, by: cellSize) {
        
        let x = i + cellSize/2 + CGFloat(generator.nextUniform()) + CGFloat.random(-_variance, _variance)
        let y = j + cellSize/2 + CGFloat(generator.nextUniform()) + CGFloat.random(-_variance, _variance)
        
        points.append(Vertex2DSimple(x: x, y: y))
      }
    }
    
    return points
  } // end of generateVertices
  */
  
  func setupBackground () {
    // set up initial bg triangles
    vertexCloud2D = [] // empty out simple vertex array
    vertexCloud3DColor = [] // empty out vertex array
    
    let v0 = Vertex2DSimple(x: 0.0, y:   0.0) // ul
    let v1 = Vertex2DSimple(x: self.bounds.size.width, y: 0.0) // ur
    let v2 = Vertex2DSimple(x: 0.0, y: self.bounds.size.height) // ll
    let v3 = Vertex2DSimple(x: self.bounds.size.width, y: self.bounds.size.height) // lr
    
    vertexCloud2D.append(v0)
    vertexCloud2D.append(v2)
    vertexCloud2D.append(v1)
    
    vertexCloud2D.append(v1)
    vertexCloud2D.append(v2)
    vertexCloud2D.append(v3)
    
    delaunayCompute()
    
    
  } // end of func setupBackground
  
  func vertexAppend (point: CGPoint) {
    let v = Vertex2DSimple(x: point.x, y: point.y)
    vertexCloud2D.append(v)
    //print ("...vertex count: \(vertexCloud2D.count)")
  } // end of func vertexAppend
  
  func delaunayCompute () {
    vertexCloud3DColor = [] // empty out vertex array

    let triangles = Delaunay().triangulate(vertexCloud2D)
    triangleCount = triangles.count
    print ("...[MTKViewDelaunayTriangulation] triangle count: \(triangleCount)")
    for triangle in triangles {
      // convert triangle vertices from device units to metal units
      let x1 = Float(triangle.vertex1.x)/Float(self.bounds.size.width)*2.0 - 1.0
      let x2 = Float(triangle.vertex2.x)/Float(self.bounds.size.width)*2.0 - 1.0
      let x3 = Float(triangle.vertex3.x)/Float(self.bounds.size.width)*2.0 - 1.0
      
      let y1 = 1.0 - Float(triangle.vertex1.y)/Float(self.bounds.size.height)*2.0
      let y2 = 1.0 - Float(triangle.vertex2.y)/Float(self.bounds.size.height)*2.0
      let y3 = 1.0 - Float(triangle.vertex3.y)/Float(self.bounds.size.height)*2.0
      
      let v1 = Vertex3DColor(x: x1, y: y1, z: 0.0, r: 1.0, g: 0.0, b: 0.0, a: 0.0)
      let v2 = Vertex3DColor(x: x2, y: y2, z: 0.0, r: 0.0, g: 1.0, b: 0.0, a: 0.0)
      let v3 = Vertex3DColor(x: x3, y: y3, z: 0.0, r: 0.0, g: 0.0, b: 1.0, a: 0.0)
      
      vertexCloud3DColor.append(v1)
      vertexCloud3DColor.append(v2)
      vertexCloud3DColor.append(v3)
             
    } // end of for triangles
    print ("...[MTKViewDelaunayTriangulation] [v] size = \(vertexCloud2D.count) [vc] size = \(vertexCloud3DColor.count)")
  }
  
  func setupTrianglesRandom(numTriangles: Int){

    //vertexCloud2D = []  // empty out 2D array
    vertexCloud3DColor = [] // empty out 3D array
    // generate n random triangles
    for _ in 0 ... numTriangles {
      //for vertex in vertices {
      let x1 = Float(CGFloat.random(-1.0, 1.0))
      let y1 = Float(CGFloat.random(-1.0, 1.0))
      let x2 = Float(CGFloat.random(-1.0, 1.0))
      let y2 = Float(CGFloat.random(-1.0, 1.0))
      let x3 = Float(CGFloat.random(-1.0, 1.0))
      let y3 = Float(CGFloat.random(-1.0, 1.0))
      
      let v1 = Vertex3DColor(x: x1, y: y1, z: 0.0, r: Float(Double.random()), g: Float(Double.random()), b: Float(Double.random()), a: 0.0)
      let v2 = Vertex3DColor(x: x2, y: y2, z: 0.0, r: Float(Double.random()), g: Float(Double.random()), b: Float(Double.random()), a: 0.0)
      let v3 = Vertex3DColor(x: x3, y: y3, z: 0.0, r: Float(Double.random()), g: Float(Double.random()), b: Float(Double.random()), a: 0.0)
      
      vertexCloud3DColor.append(v1)
      vertexCloud3DColor.append(v2)
      vertexCloud3DColor.append(v3)

    } // end of for _ in
    triangleCount = vertexCloud3DColor.count/3

    
  } // end of setupTrianglesRandom
  
  func setupTrianglesDelaunay(vertexCount: Int){
  
    // create n deulanay triangles
    ///////////////////
    //let vertices = generateVertices(self.bounds.size, cellSize: 100)
    
    vertexCloud2D = []  // empty out 2D array
    vertexCloud3DColor = [] // empty out 3D array
    
    for _ in 0 ... vertexCount {
      //for vertex in vertices {
      let x = CGFloat.random(-1.0, 1.0)
      let y = CGFloat.random(-1.0, 1.0)
      let v = Vertex2DSimple(x: x, y: y)
      vertexCloud2D.append(v)
    } // end of for
    
    
    
    let triangles = Delaunay().triangulate(vertexCloud2D)
    triangleCount = triangles.count
    
    
    for triangle in triangles {
      /*
      // convert triangle vertices from device units to metal units
      let x1 = Float(triangle.vertex1.x)/Float(self.bounds.size.width)*2.0 - 1.0
      let x2 = Float(triangle.vertex2.x)/Float(self.bounds.size.width)*2.0 - 1.0
      let x3 = Float(triangle.vertex3.x)/Float(self.bounds.size.width)*2.0 - 1.0
      
      let y1 = Float(triangle.vertex1.y)/Float(self.bounds.size.height)*2.0 - 1.0
      let y2 = Float(triangle.vertex2.y)/Float(self.bounds.size.height)*2.0 - 1.0
      let y3 = Float(triangle.vertex3.y)/Float(self.bounds.size.height)*2.0 - 1.0
      */
      let x1 = Float(triangle.vertex1.x)
      let x2 = Float(triangle.vertex2.x)
      let x3 = Float(triangle.vertex3.x)
      
      let y1 = Float(triangle.vertex1.y)
      let y2 = Float(triangle.vertex2.y)
      let y3 = Float(triangle.vertex3.y)
      
      let v1 = Vertex3DColor(x: x1, y: y1, z: 0.0, r: 1.0, g: 0.0, b: 0.0, a: 0.0)
      let v2 = Vertex3DColor(x: x2, y: y2, z: 0.0, r: 0.0, g: 1.0, b: 0.0, a: 0.0)
      let v3 = Vertex3DColor(x: x3, y: y3, z: 0.0, r: 0.0, g: 0.0, b: 1.0, a: 0.0)
      
      vertexCloud3DColor.append(v1)
      vertexCloud3DColor.append(v2)
      vertexCloud3DColor.append(v3)
    } // end of for triangles
    
    //vertexCount = vertexCloud3DColor.count
    MTKViewDelaunayTriangulationDelegate?.fpsUpdate(fps: 0, triangleCount: triangleCount) // let the delegate know of the frame update
    
  } //  end of func setupTrianglesDelaunay()
  

  
  func renderTriangles(){
    // 6. Set buffer size of objects to be drawn
    //let dataSize = vertexCount * MemoryLayout<Vertex3DColor>.size // size of the vertex data in bytes
    let dataSize = vertexCloud3DColor.count * MemoryLayout<Vertex3DColor>.stride // apple recommendation
    let vertexBuffer: MTLBuffer = device!.makeBuffer(bytes: vertexCloud3DColor, length: dataSize, options: []) // create a new buffer on the GPU
    let renderPassDescriptor: MTLRenderPassDescriptor? = self.currentRenderPassDescriptor
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
      renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCloud3DColor.count)
      
      ///////////renderCommandEncoder?.popDebugGroup()
      renderCommandEncoder?.endEncoding() // finalize renderEncoder set up
      
      commandBuffer?.present(self.currentDrawable!) // needed to make sure the new texture is presented as soon as the drawing completes
      
      // 7b. Render to pipeline
      commandBuffer?.commit() // commit and send task to gpu
      
    } // end of if renderPassDescriptor
    
  }// end of func renderTriangles()
  
  
} // end of class MTKViewDelaunayTriangulation
