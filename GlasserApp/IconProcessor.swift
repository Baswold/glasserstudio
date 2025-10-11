import Cocoa
import CoreImage
import AppKit

class IconProcessor {
    static let shared = IconProcessor()
    
    private let context = CIContext()
    private let systemPrefs = SystemPreferences.shared
    
    /// Applies liquid glass effect to an icon, respecting system icon style
    func applyLiquidGlassEffect(to image: NSImage, intensity: Double = 0.8) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // Apply filters based on system icon style
        guard let processedImage = applyFilters(to: ciImage, intensity: intensity, style: systemPrefs.iconStyle) else {
            return nil
        }
        
        // Convert back to NSImage
        guard let outputCGImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            return nil
        }
        
        let finalImage = NSImage(cgImage: outputCGImage, size: image.size)
        return finalImage
    }
    
    private func applyFilters(to image: CIImage, intensity: Double, style: IconStyle) -> CIImage? {
        var currentImage = image
        
        // Get style-specific parameters
        let (saturation, brightness, vibranceAmount) = getStyleParameters(for: style, intensity: intensity)
        
        // 1. Enhance saturation for vibrant colors (adjusted per style)
        if let saturationFilter = CIFilter(name: "CIColorControls") {
            saturationFilter.setValue(currentImage, forKey: kCIInputImageKey)
            saturationFilter.setValue(saturation, forKey: kCIInputSaturationKey)
            saturationFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
            if let output = saturationFilter.outputImage {
                currentImage = output
            }
        }
        
        // 2. Add vibrance (style-dependent)
        if vibranceAmount > 0, let vibranceFilter = CIFilter(name: "CIVibrance") {
            vibranceFilter.setValue(currentImage, forKey: kCIInputImageKey)
            vibranceFilter.setValue(vibranceAmount, forKey: "inputAmount")
            if let output = vibranceFilter.outputImage {
                currentImage = output
            }
        }
        
        // 3. Add subtle blur for glass effect (very light)
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(currentImage, forKey: kCIInputImageKey)
            blurFilter.setValue(0.5 * intensity, forKey: kCIInputRadiusKey)
            if let blurred = blurFilter.outputImage {
                // Blend the blurred version with the original
                if let blendFilter = CIFilter(name: "CISourceOverCompositing") {
                    blendFilter.setValue(currentImage, forKey: kCIInputImageKey)
                    blendFilter.setValue(blurred, forKey: kCIInputBackgroundImageKey)
                    if let output = blendFilter.outputImage {
                        currentImage = output
                    }
                }
            }
        }
        
        // 4. Add highlights for glossy effect
        if let highlightFilter = CIFilter(name: "CIHighlightShadowAdjust") {
            highlightFilter.setValue(currentImage, forKey: kCIInputImageKey)
            highlightFilter.setValue(1.2 * intensity, forKey: "inputHighlightAmount")
            highlightFilter.setValue(0.3, forKey: "inputShadowAmount")
            if let output = highlightFilter.outputImage {
                currentImage = output
            }
        }
        
        // 5. Add subtle glow
        if let glowFilter = CIFilter(name: "CIBloom") {
            glowFilter.setValue(currentImage, forKey: kCIInputImageKey)
            glowFilter.setValue(0.3 * intensity, forKey: kCIInputIntensityKey)
            glowFilter.setValue(5.0, forKey: kCIInputRadiusKey)
            if let output = glowFilter.outputImage {
                currentImage = output
            }
        }
        
        // 6. Enhance edges for definition
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(currentImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.4 * intensity, forKey: kCIInputSharpnessKey)
            if let output = sharpenFilter.outputImage {
                currentImage = output
            }
        }
        
        // 7. Apply style-specific tint overlay
        if let tintColor = systemPrefs.effectiveTintColor() {
            currentImage = applyTint(to: currentImage, color: tintColor, style: style)
        }
        
        return currentImage
    }
    
    /// Get style-specific filter parameters
    private func getStyleParameters(for style: IconStyle, intensity: Double) -> (saturation: Double, brightness: Double, vibrance: Double) {
        switch style {
        case .default:
            // Full liquid glass effect
            return (1.3 * intensity, 1.1 * intensity, 0.5 * intensity)
            
        case .dark:
            // Subdued, darker tones
            return (1.1 * intensity, 0.95 * intensity, 0.3 * intensity)
            
        case .clear:
            // More transparent, lighter effect
            return (1.2 * intensity, 1.15 * intensity, 0.4 * intensity)
            
        case .tinted:
            // Enhanced for tinting with accent color
            return (1.4 * intensity, 1.05 * intensity, 0.6 * intensity)
        }
    }
    
    /// Apply color tint overlay based on style
    private func applyTint(to image: CIImage, color: NSColor, style: IconStyle) -> CIImage {
        // Convert NSColor to CIColor
        guard let ciColor = CIColor(color: color) else { return image }
        
        // Create color overlay
        let colorFilter = CIFilter(name: "CIConstantColorGenerator")
        colorFilter?.setValue(ciColor, forKey: kCIInputColorKey)
        
        guard let colorImage = colorFilter?.outputImage else { return image }
        
        // Apply blend mode based on style
        let blendMode: String
        let opacity: Double
        
        switch style {
        case .tinted:
            blendMode = "CIColorBlendMode"
            opacity = 0.25
        case .dark:
            blendMode = "CIMultiplyBlendMode"
            opacity = 0.15
        default:
            return image
        }
        
        // Crop color to image bounds
        let croppedColor = colorImage.cropped(to: image.extent)
        
        // Apply blend
        if let blendFilter = CIFilter(name: blendMode) {
            blendFilter.setValue(croppedColor, forKey: kCIInputImageKey)
            blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
            
            if let blended = blendFilter.outputImage {
                // Adjust opacity
                if let opacityFilter = CIFilter(name: "CIColorMatrix") {
                    opacityFilter.setValue(blended, forKey: kCIInputImageKey)
                    opacityFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
                    opacityFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
                    opacityFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
                    opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(opacity)), forKey: "inputAVector")
                    
                    if let adjustedBlend = opacityFilter.outputImage {
                        // Composite over original
                        if let composite = CIFilter(name: "CISourceOverCompositing") {
                            composite.setValue(adjustedBlend, forKey: kCIInputImageKey)
                            composite.setValue(image, forKey: kCIInputBackgroundImageKey)
                            return composite.outputImage ?? image
                        }
                    }
                }
                return blended
            }
        }
        
        return image
    }
    
    /// Process icon and save to file
    func processAndSaveIcon(inputPath: String, outputPath: String, intensity: Double = 0.8) -> Bool {
        guard let image = NSImage(contentsOfFile: inputPath) else {
            print("Failed to load image from: \(inputPath)")
            return false
        }
        
        guard let processedImage = applyLiquidGlassEffect(to: image, intensity: intensity) else {
            print("Failed to process image: \(inputPath)")
            return false
        }
        
        return saveImage(processedImage, to: outputPath)
    }
    
    private func saveImage(_ image: NSImage, to path: String) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            print("Failed to convert image to PNG")
            return false
        }
        
        do {
            try pngData.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            print("Failed to save image: \(error)")
            return false
        }
    }
}

extension NSImage {
    func cgImage(forProposedRect proposedDestRect: UnsafeMutablePointer<NSRect>?, context: NSGraphicsContext?, hints: [NSImageRep.HintKey : Any]?) -> CGImage? {
        guard let imageData = self.tiffRepresentation,
              let sourceData = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(sourceData, 0, nil) else {
            return nil
        }
        return cgImage
    }
}
