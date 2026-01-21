//
//  MetalRenderer.swift
//  AIDrawing
//
//  Metal-based renderer for low-latency ink strokes
//

import Foundation
import Metal
import MetalKit
import CoreGraphics
import simd

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Vertex Structure

struct InkVertex {
    var position: SIMD2<Float>
    var texCoord: SIMD2<Float>
    var color: SIMD4<Float>
    var width: Float
}

// MARK: - Uniforms

struct Uniforms {
    var projectionMatrix: simd_float4x4
    var viewportSize: SIMD2<Float>
}

// MARK: - Metal Renderer

class MetalRenderer: NSObject {
    private(set) var device: MTLDevice!  // Changed from private to private(set) for TouchCaptureView access
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var pipelineStatePredicted: MTLRenderPipelineState!

    // Vertex buffers (ring buffer for efficiency)
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?

    // Current stroke data
    private var currentStrokeVertices: [InkVertex] = []
    private var committedStrokes: [[InkVertex]] = []

    // AI-generated strokes (rendered separately for visual distinction)
    private var aiStrokes: [[InkVertex]] = []

    // Predicted stroke (ghost rendering)
    private var predictedStrokeVertices: [InkVertex] = []

    private var viewportSize: CGSize = .zero

    // Debug info
    var currentStrokeVerticesCount: Int {
        return currentStrokeVertices.count
    }

    override init() {
        super.init()
        setupMetal()
    }

    private func setupMetal() {
        // Get default Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device

        // Create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        self.commandQueue = commandQueue

        // Load shaders and create pipeline
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load Metal library")
        }

        let vertexFunction = library.makeFunction(name: "ink_vertex_shader")
        let fragmentFunction = library.makeFunction(name: "ink_fragment_shader_aa")
        let fragmentFunctionPredicted = library.makeFunction(name: "ink_fragment_shader_predicted")

        // Pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Enable alpha blending
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

        // Vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        // Position
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // TexCoord
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        // Color
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD2<Float>>.stride * 2
        vertexDescriptor.attributes[2].bufferIndex = 0
        // Width
        vertexDescriptor.attributes[3].format = .float
        vertexDescriptor.attributes[3].offset = MemoryLayout<SIMD2<Float>>.stride * 2 + MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[3].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<InkVertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

            // Create predicted stroke pipeline (with different fragment shader)
            pipelineDescriptor.fragmentFunction = fragmentFunctionPredicted
            self.pipelineStatePredicted = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }

        // Create uniform buffer
        self.uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: [])

        print("🎨 MetalRenderer initialized successfully")
    }

    // MARK: - Stroke Management

    /// Enqueue new points for the current in-progress stroke
    func enqueuePoints(_ points: [StrokePoint], color: UIColor, baseWidth: CGFloat, scale: CGFloat) {
        print("🔧 enqueuePoints called with \(points.count) points, scale: \(scale)")
        let newVertices = expandPointsToTriangles(points, color: color, baseWidth: baseWidth, scale: scale)
        print("🔧 expandPointsToTriangles returned \(newVertices.count) vertices")
        currentStrokeVertices.append(contentsOf: newVertices)
        print("🔧 currentStrokeVertices now has \(currentStrokeVertices.count) total vertices")
    }

    /// Clear current stroke and start fresh
    func clearCurrentStroke() {
        currentStrokeVertices.removeAll()
    }

    /// Commit current stroke to permanent buffer
    func commitCurrentStroke() {
        if !currentStrokeVertices.isEmpty {
            committedStrokes.append(currentStrokeVertices)
            currentStrokeVertices.removeAll()
        }
    }

    /// Set predicted stroke vertices (for ghost rendering)
    func setPredictedStroke(_ points: [StrokePoint], color: UIColor, baseWidth: CGFloat, scale: CGFloat) {
        predictedStrokeVertices = expandPointsToTriangles(points, color: color, baseWidth: baseWidth, scale: scale)
    }

    /// Clear predicted stroke
    func clearPredictedStroke() {
        predictedStrokeVertices.removeAll()
    }

    /// Add an AI-generated stroke
    func addAIStroke(_ points: [StrokePoint], color: UIColor, baseWidth: CGFloat, scale: CGFloat) {
        let vertices = expandPointsToTriangles(points, color: color, baseWidth: baseWidth, scale: scale)
        if !vertices.isEmpty {
            aiStrokes.append(vertices)
        }
    }

    /// Clear all AI strokes
    func clearAIStrokes() {
        aiStrokes.removeAll()
    }

    /// Erase strokes that intersect with the given path (for eraser tool)
    func eraseStrokesIntersecting(_ eraserPath: [StrokePoint]) {
        guard !eraserPath.isEmpty else { return }

        // Simple bounding box intersection for now
        let eraserBounds = calculateBounds(eraserPath)

        // Check committed strokes
        committedStrokes.removeAll { strokeVertices in
            let strokeBounds = calculateStrokeBounds(strokeVertices)
            return strokeBounds.intersects(eraserBounds)
        }

        // Check AI strokes
        aiStrokes.removeAll { strokeVertices in
            let strokeBounds = calculateStrokeBounds(strokeVertices)
            return strokeBounds.intersects(eraserBounds)
        }

        print("🧹 Eraser: Removed intersecting strokes. Remaining: \(committedStrokes.count) user + \(aiStrokes.count) AI")
    }

    private func calculateBounds(_ points: [StrokePoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        var minX = points[0].location.x
        var maxX = points[0].location.x
        var minY = points[0].location.y
        var maxY = points[0].location.y

        for point in points {
            minX = min(minX, point.location.x)
            maxX = max(maxX, point.location.x)
            minY = min(minY, point.location.y)
            maxY = max(maxY, point.location.y)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func calculateStrokeBounds(_ vertices: [InkVertex]) -> CGRect {
        guard !vertices.isEmpty else { return .zero }
        var minX = vertices[0].position.x
        var maxX = vertices[0].position.x
        var minY = vertices[0].position.y
        var maxY = vertices[0].position.y

        for vertex in vertices {
            minX = min(minX, vertex.position.x)
            maxX = max(maxX, vertex.position.x)
            minY = min(minY, vertex.position.y)
            maxY = max(maxY, vertex.position.y)
        }

        return CGRect(x: CGFloat(minX), y: CGFloat(minY),
                      width: CGFloat(maxX - minX), height: CGFloat(maxY - minY))
    }

    /// Clear all strokes
    func clearAll() {
        currentStrokeVertices.removeAll()
        committedStrokes.removeAll()
        aiStrokes.removeAll()
        predictedStrokeVertices.removeAll()
    }

    // MARK: - Rendering

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        // Update viewport size if changed
        let newSize = view.drawableSize
        if viewportSize != newSize {
            viewportSize = newSize
        }

        // Update uniforms
        updateUniforms()

        // Draw committed strokes
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)

        for strokeVertices in committedStrokes {
            drawStroke(strokeVertices, encoder: renderEncoder)
        }

        // Draw AI-generated strokes
        for aiStrokeVertices in aiStrokes {
            drawStroke(aiStrokeVertices, encoder: renderEncoder)
        }

        // Draw current in-progress stroke
        if !currentStrokeVertices.isEmpty {
            drawStroke(currentStrokeVertices, encoder: renderEncoder)
        }

        // Draw predicted stroke (ghost)
        if !predictedStrokeVertices.isEmpty {
            renderEncoder.setRenderPipelineState(pipelineStatePredicted)
            drawStroke(predictedStrokeVertices, encoder: renderEncoder)
        }

        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func drawStroke(_ vertices: [InkVertex], encoder: MTLRenderCommandEncoder) {
        guard !vertices.isEmpty else { return }

        // Create vertex buffer for this stroke
        let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<InkVertex>.stride,
            options: []
        )

        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }

    private func updateUniforms() {
        guard let uniformBuffer = uniformBuffer else { return }

        // Create orthographic projection matrix
        let width = Float(viewportSize.width)
        let height = Float(viewportSize.height)

        print("🖼️ Viewport: \(width) x \(height)")

        let projectionMatrix = simd_float4x4.orthographic(
            left: 0,
            right: width,
            bottom: height,
            top: 0,
            near: -1,
            far: 1
        )

        var uniforms = Uniforms(
            projectionMatrix: projectionMatrix,
            viewportSize: SIMD2<Float>(width, height)
        )

        let uniformsPointer = uniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
        uniformsPointer.pointee = uniforms
    }

    // MARK: - Geometry Expansion

    /// Expand stroke points to triangle vertices with bevel joins
    private func expandPointsToTriangles(_ points: [StrokePoint], color: UIColor, baseWidth: CGFloat, scale: CGFloat) -> [InkVertex] {
        guard points.count >= 2 else {
            print("⚠️ expandPointsToTriangles: Not enough points (\(points.count))")
            return []
        }

        // Apply Chaikin smoothing for smoother curves
        let smoothedPoints = StrokeSmoother.chaikinSmooth(points: points, iterations: 1)

        var vertices: [InkVertex] = []

        // Convert UIColor to SIMD4 once
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let colorVec = SIMD4<Float>(Float(r), Float(g), Float(b), Float(a))

        print("🎨 Expanding \(points.count) points to triangles (smoothed to \(smoothedPoints.count)), baseWidth: \(baseWidth), scale: \(scale)")

        // Store previous segment's end vertices for join generation
        var prevRight: SIMD2<Float>?
        var prevLeft: SIMD2<Float>?

        for i in 0..<(smoothedPoints.count - 1) {
            let p0 = smoothedPoints[i]
            let p1 = smoothedPoints[i + 1]

            // Calculate width based on force (pressure-sensitive)
            let width0 = Float(baseWidth * (0.3 + 0.7 * p0.force) * scale)
            let width1 = Float(baseWidth * (0.3 + 0.7 * p1.force) * scale)

            // Calculate perpendicular direction
            let dx = p1.location.x - p0.location.x
            let dy = p1.location.y - p0.location.y
            let length = hypot(dx, dy)

            if length < 0.001 {
                continue
            }

            let nx = -dy / length
            let ny = dx / length

            // Scale coordinates to match drawable size (pixels)
            let pos0 = SIMD2<Float>(Float(p0.location.x * scale), Float(p0.location.y * scale))
            let pos1 = SIMD2<Float>(Float(p1.location.x * scale), Float(p1.location.y * scale))

            let normal = SIMD2<Float>(Float(nx), Float(ny))

            // Current segment edge positions
            let currLeft = pos0 - normal * width0 * 0.5
            let currRight = pos0 + normal * width0 * 0.5
            let nextLeft = pos1 - normal * width1 * 0.5
            let nextRight = pos1 + normal * width1 * 0.5

            // Add bevel join if this isn't the first segment
            if let prevR = prevRight, let prevL = prevLeft {
                // Create join triangles to fill gap between previous segment end and current segment start
                let center = pos0

                // Determine which side needs the join based on turn direction
                // Cross product tells us if we're turning left or right
                let v1x = prevR.x - center.x
                let v1y = prevR.y - center.y
                let v2x = currRight.x - center.x
                let v2y = currRight.y - center.y
                let cross = v1x * v2y - v1y * v2x

                if cross > 0 {
                    // Right turn - join on right side
                    vertices.append(InkVertex(position: center, texCoord: SIMD2<Float>(0.5, 0.5), color: colorVec, width: width0))
                    vertices.append(InkVertex(position: prevR, texCoord: SIMD2<Float>(1, 0), color: colorVec, width: width0))
                    vertices.append(InkVertex(position: currRight, texCoord: SIMD2<Float>(1, 0), color: colorVec, width: width0))
                } else {
                    // Left turn - join on left side
                    vertices.append(InkVertex(position: center, texCoord: SIMD2<Float>(0.5, 0.5), color: colorVec, width: width0))
                    vertices.append(InkVertex(position: currLeft, texCoord: SIMD2<Float>(0, 0), color: colorVec, width: width0))
                    vertices.append(InkVertex(position: prevL, texCoord: SIMD2<Float>(0, 0), color: colorVec, width: width0))
                }
            }

            // Create quad for this segment
            let v0 = InkVertex(position: currLeft, texCoord: SIMD2<Float>(0, 0), color: colorVec, width: width0)
            let v1 = InkVertex(position: currRight, texCoord: SIMD2<Float>(1, 0), color: colorVec, width: width0)
            let v2 = InkVertex(position: nextLeft, texCoord: SIMD2<Float>(0, 1), color: colorVec, width: width1)
            let v3 = InkVertex(position: nextRight, texCoord: SIMD2<Float>(1, 1), color: colorVec, width: width1)

            // Triangle 1: v0, v1, v2
            vertices.append(v0)
            vertices.append(v1)
            vertices.append(v2)

            // Triangle 2: v1, v3, v2
            vertices.append(v1)
            vertices.append(v3)
            vertices.append(v2)

            // Store this segment's end vertices for next join
            prevLeft = nextLeft
            prevRight = nextRight
        }

        print("🎨 Generated \(vertices.count) vertices from \(smoothedPoints.count) smoothed points (includes joins)")
        return vertices
    }
}

// MARK: - Matrix Extensions

extension simd_float4x4 {
    static func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> simd_float4x4 {
        let ral = right + left
        let rsl = right - left
        let tab = top + bottom
        let tsb = top - bottom
        let fan = far + near
        let fsn = far - near

        return simd_float4x4(
            SIMD4<Float>(2.0 / rsl, 0, 0, 0),
            SIMD4<Float>(0, 2.0 / tsb, 0, 0),
            SIMD4<Float>(0, 0, -2.0 / fsn, 0),
            SIMD4<Float>(-ral / rsl, -tab / tsb, -fan / fsn, 1)
        )
    }
}
