//
//  mglColorRenderingConfig.swift
//  mglMetal
//
//  This caputres "things we need to do to set up for color rendering".
//  What does that mean?  Things like setting up a Metal render pass descriptor
//  And managing textures to hold color and/or depth data.
//
//  Why is it worth extracthing this out of the mglRenderer?
//  Because we have at least two different flavors of color rendering:
//  Normal on-screen rendering, and off-screen rendering to a chosen texture.
//
//  There are several places in mglRenderer where we do similar-but-differrent things,
//  Depending on which flavor of color rendering we're doing.
//  This caused too many if-else sections scattered around the code,
//  that all needed to work together.
//  Better to group all the "ifs" into one place, and the "elses" into another.
//
//  Created by Benjamin Heasly on 5/2/22.
//  Copyright © 2022 GRU. All rights reserved.
//

import Foundation
import MetalKit
import os.log


// This declares the operations that mglRenderer relies on,
// to set up Metal rendering passes and pipelines.
// It will have different implementations for on-screen vs off-screen rendering.
protocol mglColorRenderingConfig {
    var dotsPipelineState: MTLRenderPipelineState { get }
    var arcsPipelineState: MTLRenderPipelineState { get }
    var verticesWithColorPipelineState: MTLRenderPipelineState { get }
    var texturePipelineState: MTLRenderPipelineState { get }

    func getRenderPassDescriptor(view: MTKView) -> MTLRenderPassDescriptor?

    func finishDrawing(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable)
    func frameGrab()->(width: Int, height: Int, pointer: UnsafeMutablePointer<Float>?)
}

class mglOnscreenRenderingConfig : mglColorRenderingConfig {
    let dotsPipelineState: MTLRenderPipelineState
    let arcsPipelineState: MTLRenderPipelineState
    let verticesWithColorPipelineState: MTLRenderPipelineState
    let texturePipelineState: MTLRenderPipelineState

    init?(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        // Until an explicit OOP command model exists, we can just call static functions of mglRenderer.
        do {
            dotsPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.dotsPipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            arcsPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.arcsPipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            verticesWithColorPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.drawVerticesPipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            texturePipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.bltTexturePipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
        } catch let error {
            os_log("Could not create onscreen pipeline state: %@", log: .default, type: .error, String(describing: error))
            return nil
        }
    }

    func getRenderPassDescriptor(view: MTKView) -> MTLRenderPassDescriptor? {
        return view.currentRenderPassDescriptor
    }

    func finishDrawing(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable) {
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // frameGrab, since everything is being drawn to a CAMetalDrawable, it does not
    // appear to be trivial to grab the bytes - it seems like a copy of all commands
    // has to be drawn into an offscreen texture, so for now, this function just returns
    // nil to notify that the frameGrab is impossible
    func frameGrab() -> (width: Int, height: Int, pointer: UnsafeMutablePointer<Float>?) {
      return (0,0,nil)
    }

}

class mglOffScreenTextureRenderingConfig : mglColorRenderingConfig {
    let dotsPipelineState: MTLRenderPipelineState
    let arcsPipelineState: MTLRenderPipelineState
    let verticesWithColorPipelineState: MTLRenderPipelineState
    let texturePipelineState: MTLRenderPipelineState

    let colorTexture: MTLTexture
    let depthStencilTexture: MTLTexture
    let renderPassDescriptor: MTLRenderPassDescriptor

    init?(device: MTLDevice, library: MTLLibrary, view: MTKView, texture: MTLTexture) {
        self.colorTexture = texture

        let depthStencilTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: view.depthStencilPixelFormat,
            width: texture.width,
            height: texture.height,
            mipmapped: false)
        depthStencilTextureDescriptor.storageMode = .private
        depthStencilTextureDescriptor.usage = .renderTarget
        guard let depthStencilTexture = device.makeTexture(descriptor: depthStencilTextureDescriptor) else {
            os_log("Could not create offscreen depth-and-stencil texture, got nil!", log: .default, type: .error)
            return nil
        }
        self.depthStencilTexture = depthStencilTexture

        renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderPassDescriptor.depthAttachment.texture = depthStencilTexture
        renderPassDescriptor.stencilAttachment.texture = depthStencilTexture

        do {
            dotsPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.dotsPipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            arcsPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.arcsPipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            verticesWithColorPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.drawVerticesPipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            texturePipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.bltTexturePipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
        } catch let error {
            os_log("Could not create offscreen pipeline state: %@", log: .default, type: .error, String(describing: error))
            return nil
        }
    }

    func getRenderPassDescriptor(view: MTKView) -> MTLRenderPassDescriptor? {
        renderPassDescriptor.colorAttachments[0].clearColor = view.clearColor
        renderPassDescriptor.depthAttachment.clearDepth = view.clearDepth
        return renderPassDescriptor
    }

    func finishDrawing(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable) {
        let bltCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        bltCommandEncoder?.synchronize(resource: colorTexture)
        bltCommandEncoder?.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()

        // Wait until the bltCommandEncoder is done syncing data from GPU to CPU.
        commandBuffer.waitUntilCompleted()
    }
    
    // frameGrab, this will write the bytes of the texture into an array
    func frameGrab() -> (width: Int, height: Int, pointer: UnsafeMutablePointer<Float>?) {
        // first make sure we have the right MTLTexture format (this should always be the same - it's set in
        // the createTexture function in mglCommandInterface
        if (colorTexture.pixelFormat == MTLPixelFormat.rgba32Float) {
            // compute size needed
            let dataSize = colorTexture.width * colorTexture.height * 4 * MemoryLayout<Float>.stride
            // set the region
            let region = MTLRegionMake2D(0,0,colorTexture.width,colorTexture.height)
            let bytesPerRow = colorTexture.width * 4 * MemoryLayout<Float>.stride
            let destinationBuffer = UnsafeMutablePointer<Float>.allocate(capacity: dataSize)
            // just for debugging, set to a value, to make sure we can retrieve that, if nothing else.
            destinationBuffer.initialize(repeating: 45, count: dataSize)
            // ok, get the bytes
            colorTexture.getBytes(destinationBuffer, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
            // return pointer to frame data
            return (colorTexture.width, colorTexture.height, destinationBuffer)
        }
        else {
            // could not get bytes, return 0,0,nil
            return (0,0,nil)
        }
    }
}
