import UIKit

final class CellCachedIndicatorView: UIView {
    let size: CGFloat

    override var intrinsicContentSize: CGSize { .init(width: size, height: size) }

    init(size: CGFloat = 20) {
        self.size = size
        super.init(frame: .init(origin: .zero, size: .init(width: size, height: size)))
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let maskPath = UIBezierPath()
        maskPath.move(to: .init(x: 0, y: 0))
        maskPath.addLine(to: .init(x: size, y: 0))
        maskPath.addLine(to: .init(x: 0, y: size))
        maskPath.close()

        let triangleMaskLayer = CAShapeLayer()
        triangleMaskLayer.path = maskPath.cgPath

        backgroundColor = ViewObjects.shared().currentDarkColor()
        layer.mask = triangleMaskLayer
    }

}
