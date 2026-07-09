import UIKit

class FaceGuideOverlay: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)
        
        let ovalRect = rect.insetBy(dx: 10, dy: 10)
        
        // Tinted mask outside oval
        ctx.saveGState()
        let maskPath = UIBezierPath(ovalIn: ovalRect)
        maskPath.addClip()
        ctx.setBlendMode(.destinationOut)
        UIColor(white: 0.0, alpha: 0.45).setFill()
        UIBezierPath(rect: rect).fill()
        ctx.restoreGState()
        
        // Dashed border
        let border = UIBezierPath(ovalIn: ovalRect)
        border.lineWidth = 3
        UIColor.systemBlue.setStroke()
        border.setLineDash([12, 6], count: 2, phase: 0)
        border.stroke()
        
        // Corner dots
        let dotSize: CGFloat = 12
        UIColor.systemBlue.setFill()
        let offsets = [
            CGPoint(x: ovalRect.minX, y: ovalRect.minY),
            CGPoint(x: ovalRect.maxX, y: ovalRect.minY),
            CGPoint(x: ovalRect.minX, y: ovalRect.maxY),
            CGPoint(x: ovalRect.maxX, y: ovalRect.maxY)
        ]
        for pt in offsets {
            let r = CGRect(x: pt.x - dotSize/2, y: pt.y - dotSize/2, width: dotSize, height: dotSize)
            UIBezierPath(ovalIn: r).fill()
        }
        
        // Static scan line
        let lineY = ovalRect.midY
        let line = UIBezierPath()
        line.move(to: CGPoint(x: ovalRect.minX, y: lineY))
        line.addLine(to: CGPoint(x: ovalRect.maxX, y: lineY))
        line.lineWidth = 2
        UIColor.systemBlue.withAlphaComponent(0.6).setStroke()
        line.stroke()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        animateScanLine()
    }
    
    private func animateScanLine() {
        let line = UIView(frame: CGRect(x: bounds.insetBy(dx: 10, dy: 10).minX,
                                        y: bounds.midY,
                                        width: bounds.width - 20,
                                        height: 2))
        line.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        line.layer.cornerRadius = 1
        addSubview(line)
        
        let anim = CABasicAnimation(keyPath: "position.y")
        anim.fromValue = bounds.midY - 100
        anim.toValue = bounds.midY + 100
        anim.duration = 2.2
        anim.autoreverses = true
        anim.repeatCount = .infinity
        line.layer.add(anim, forKey: "scan")
    }
}
