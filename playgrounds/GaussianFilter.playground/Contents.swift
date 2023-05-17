import Cocoa
import Accelerate

let imageURL = URL(fileURLWithPath: <#input image path#>)
let outputURL = URL(fileURLWithPath: <#output image path#>)

// gaussian kernel size
let filterSize = 3
let sigma: Float = 0.849321

func gaussian(x: Float, y: Float, sigma: Float) -> Float {
    let variance = max(sigma * sigma, .leastNonzeroMagnitude)

    return (1.0 / (.pi * 2 * variance)) * pow(Float(M_E), -(pow(x, 2) + pow(y, 2)) / (2 * variance))
}

func gaussianKernel(size: Int, sigma: Float) -> [Float] {
    var filter = [Float]()
    var sum: Float = 0
    for y in -size/2 ... size/2 {
        for x in -size/2 ... size/2 {
            let value = gaussian(x: Float(x), y: Float(y), sigma: sigma)
            filter.append(value)
            sum += value
        }
    }
    return filter.map { $0 / sum }
}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}


// Load input image
guard let nsImage = NSImage(contentsOf: imageURL) else {
    fatalError("image file not found")
}

var imageRect = CGRect(origin: .zero, size: nsImage.size)
guard let cgImage = nsImage.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {
    fatalError("cannot convert to CGImage")
}

guard let pixelData = cgImage.dataProvider?.data as? Data else {
    fatalError("cannot get pixel data")
}

let pixelCount = Int(cgImage.width * cgImage.height)
let componentCount = cgImage.bytesPerRow / cgImage.width

var newPixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: pixelData.count)
newPixelData.initialize(repeating: 0, count: pixelData.count)

let bmpContext = CGContext(
    data: newPixelData,
    width: cgImage.width,
    height: cgImage.height,
    bitsPerComponent: cgImage.bitsPerComponent,
    bytesPerRow: cgImage.bytesPerRow,
    space: CGColorSpaceCreateDeviceRGB() ,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

bmpContext.draw(cgImage, in: .init(origin: .zero, size: .init(width: cgImage.width, height: cgImage.height)))

var gaussianFilter: [Float] = gaussianKernel(size: filterSize, sigma: sigma)

var componentPixels = [Float](repeating: 0, count: pixelCount)
var tmp = [Float](repeating: 0, count: pixelCount)

for index in 0 ..< componentCount {
    vDSP_vfltu8(newPixelData + index, vDSP_Stride(componentCount), &componentPixels, 1, vDSP_Length(pixelCount))
    vDSP_imgfir(&componentPixels, vDSP_Length(cgImage.height), vDSP_Length(cgImage.width), &gaussianFilter, &tmp, vDSP_Length(filterSize), vDSP_Length(filterSize))
    vDSP_vfixu8(tmp, 1, newPixelData + index, vDSP_Stride(componentCount), vDSP_Length(pixelCount))
}

guard let resultCGImage = bmpContext.makeImage() else {
    fatalError()
}

let resultNSImage = NSImage(cgImage: resultCGImage, size: .init(width: resultCGImage.width, height: resultCGImage.height))

resultNSImage.pngWrite(to: outputURL)
