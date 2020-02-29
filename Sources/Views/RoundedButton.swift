import UIKit

final class RoundedButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel?.font = .preferredFont(for: .action)
        contentEdgeInsets = .init(top: 6, left: 10, bottom: 6, right: 10)

        updateColors()

        addTarget(self, action: #selector(didTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(didTouchUp), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var titleLabelHeight: CGFloat {
        titleLabel?.font.lineHeight ?? 0
    }

    private var contentHeight: CGFloat {
        titleLabelHeight + contentEdgeInsets.top + contentEdgeInsets.bottom
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColors()
    }

    private func updateColors() {
        setTitleColor(.black, for: .normal)
        setTitleColor(#colorLiteral(red: 0.09454790503, green: 0.4650266767, blue: 0.9471945167, alpha: 1), for: .selected)
        setTitleColor(#colorLiteral(red: 0.09454790503, green: 0.4650266767, blue: 0.9471945167, alpha: 1), for: [.selected, .highlighted])
        setBackgroundImage(with: #colorLiteral(red: 0.8937479854, green: 0.9016788602, blue: 0.9223432541, alpha: 1), for: .normal)
        setBackgroundImage(with: #colorLiteral(red: 0.8190190792, green: 0.8349635005, blue: 0.8598470092, alpha: 1), for: .highlighted)
        setBackgroundImage(with: #colorLiteral(red: 0.9058823529, green: 0.9529411765, blue: 1, alpha: 1), for: .selected)
        setBackgroundImage(with: #colorLiteral(red: 0.8274509804, green: 0.8745098039, blue: 1, alpha: 1), for: [.selected, .highlighted])
    }

    private func setBackgroundImage(with color: UIColor, for state: UIControl.State) {
        let descriptor = ImagesGenerator.Descriptor(color: color, cornerRadius: contentHeight / 2)
        let image = ImagesGenerator.shared.makeImage(for: descriptor)
        setBackgroundImage(image, for: state)
    }

    @objc private func didTouchDown() {
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.transform = .init(scaleX: 0.95, y: 0.95)
        }
    }

    @objc private func didTouchUp() {
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.transform = .identity
        }
    }
}
