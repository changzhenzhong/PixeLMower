import SpriteKit
import UIKit

struct PixelTextureGenerator {
    static func generatePlayerTexture(size: Int) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let img = renderer.image { ctx in
            let pixels: [(Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (6,2,1,1,1,1),(7,2,1,1,1,1),(8,2,1,1,1,1),(9,2,1,1,1,1),
                (5,3,1,1,1,1),(6,3,0.2,0.4,0.9,1),(7,3,1,1,1,1),(8,3,1,1,1,1),(9,3,0.2,0.4,0.9,1),(10,3,1,1,1,1),
                (6,4,0.3,0.5,0.9,1),(7,4,1,1,1,1),(8,4,1,1,1,1),(9,4,0.3,0.5,0.9,1),
                (5,5,0.3,0.5,0.9,1),(6,5,1,1,1,1),(7,5,1,1,1,1),(8,5,1,1,1,1),(9,5,1,1,1,1),(10,5,0.3,0.5,0.9,1),
                (6,6,0.2,0.2,0.3,1),(9,6,0.2,0.2,0.3,1),
                (6,7,0.15,0.15,0.25,1),(9,7,0.15,0.15,0.25,1),
            ]
            for (x, y, r, g, b, a) in pixels {
                UIColor(red: r, green: g, blue: b, alpha: a).setFill()
                UIRectFill(CGRect(x: CGFloat(x), y: CGFloat(y), width: 1, height: 1))
            }
        }
        return SKTexture(image: img)
    }

    static func generateEnemyTexture(size: Int) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let img = renderer.image { ctx in
            let colors: [(CGFloat,CGFloat,CGFloat)] = [
                (0.9,0.2,0.2),(0.7,0.1,0.5),(0.2,0.7,0.2),(0.6,0.3,0.1)
            ]
            let c = colors.randomElement()!
            let shape: [(Int,Int)] = [
                (4,3),(5,3),(6,3),(7,3),
                (3,4),(4,4),(7,4),(8,4),
                (3,5),(5,5),(6,5),(8,5),
                (4,6),(7,6),
                (5,7),(6,7),
            ]
            for (x, y) in shape {
                UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1).setFill()
                UIRectFill(CGRect(x: CGFloat(x), y: CGFloat(y), width: 1, height: 1))
            }
        }
        return SKTexture(image: img)
    }

    static func generateBladeTexture(size: Int) -> SKTexture {
        let height = size / 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: height))
        let img = renderer.image { ctx in
            UIColor(red: 0.9, green: 0.8, blue: 0.3, alpha: 1).setFill()
            for x in 2..<7 {
                UIRectFill(CGRect(x: CGFloat(x), y: 0, width: 1, height: CGFloat(height)))
            }
            UIColor(red: 1, green: 0.95, blue: 0.6, alpha: 1).setFill()
            UIRectFill(CGRect(x: 3, y: 0, width: 1, height: CGFloat(height)))
        }
        return SKTexture(image: img)
    }
}
