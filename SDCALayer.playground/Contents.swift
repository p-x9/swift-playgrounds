import Cocoa
import SDCALayer

let layer = CAShapeLayer()
layer.path = CGMutablePath(rect: .init(x: 0, y: 0, width: 5, height: 5), transform: nil)
layer.borderWidth = 0.8
layer.borderColor = .init(red: 0.5, green: 0.2, blue: 1, alpha: 0.9)

print(SDCALayer(model: layer.codable())!.yaml!)
