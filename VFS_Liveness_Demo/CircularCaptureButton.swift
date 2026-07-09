import UIKit

class CircularCaptureButton: UIControl {
    
    private let outerRing: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderWidth = 4
        v.layer.borderColor = UIColor.white.cgColor
        v.layer.cornerRadius = 36
        return v
    }()
    
    private let innerCircle: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 28
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        addSubview(outerRing)
        outerRing.addSubview(innerCircle)
        
        outerRing.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            outerRing.widthAnchor.constraint(equalToConstant: 72),
            outerRing.heightAnchor.constraint(equalToConstant: 72),
            outerRing.centerXAnchor.constraint(equalTo: centerXAnchor),
            outerRing.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            innerCircle.widthAnchor.constraint(equalToConstant: 56),
            innerCircle.heightAnchor.constraint(equalToConstant: 56),
            innerCircle.centerXAnchor.constraint(equalTo: outerRing.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: outerRing.centerYAnchor)
        ])
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        UIView.animate(withDuration: 0.15) {
            self.innerCircle.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.outerRing.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.outerRing.layer.borderColor = UIColor.systemBlue.cgColor
        }
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        UIView.animate(withDuration: 0.2) {
            self.innerCircle.transform = .identity
            self.outerRing.transform = .identity
            self.outerRing.layer.borderColor = UIColor.white.cgColor
        }
        sendActions(for: .touchUpInside)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        UIView.animate(withDuration: 0.2) {
            self.innerCircle.transform = .identity
            self.outerRing.transform = .identity
        }
    }
}
