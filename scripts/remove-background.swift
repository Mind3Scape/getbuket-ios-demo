import Foundation
import Vision
import CoreImage
import ImageIO
import UniformTypeIdentifiers

// Apple's on-device foreground segmentation. Original photographs are untouched.
let context = CIContext()
for path in CommandLine.arguments.dropFirst() {
    do {
        let url = URL(fileURLWithPath: path)
        let handler = VNImageRequestHandler(url: url)
        let request = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([request])
        guard let observation = request.results?.first else { continue }
        let buffer = try observation.generateMaskedImage(ofInstances: observation.allInstances, from: handler, croppedToInstancesExtent: true)
        let image = CIImage(cvPixelBuffer: buffer)
        let output = URL(fileURLWithPath: "assets/cutouts/\(url.deletingPathExtension().lastPathComponent).png")
        try context.writePNGRepresentation(of: image, to: output, format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
        print("Saved \(output.lastPathComponent)")
    } catch { fputs("\(path): \(error)\n", stderr); exit(1) }
}
