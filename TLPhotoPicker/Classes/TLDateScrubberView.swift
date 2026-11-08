//
//  TLDateScrubberView.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 2026. 11. 8..
//  Copyright © 2026년 wade.hawk. All rights reserved.
//

import UIKit

/// A draggable thumb on the trailing edge of the grid that shows the month under the finger
/// and jumps the grid there. Touches outside the thumb pass through to the grid.
final class TLDateScrubberView: UIView {
    // MARK: - Data Source
    var navigatorProvider: (() -> TLAssetDateNavigator?)?
    var scrollToAssetIndex: ((Int) -> Void)?
    var topAssetIndex: (() -> Int?)?
    /// Maps an asset index to the grid's index path (e.g. to skip the camera cell).
    var indexPathForAssetIndex: ((Int) -> IndexPath?)?

    // MARK: - Configuration
    private let configure: TLDateScrubberConfigure
    private let formatter: DateFormatter

    // MARK: - Subviews
    private let thumbView = TLDateScrubberThumbView()
    private let thumbIconView = UIImageView()
    private let bubbleLabel = TLPaddingLabel()
    private var yearLabels = [UILabel]()

    // MARK: - State
    private weak var scrollView: UIScrollView?
    private var observations = [NSKeyValueObservation]()
    private var isScrubbing = false
    private var grabOffset: CGFloat = 0
    private var thumbCenterY: CGFloat = 0
    private var lastLabel: String?
    private var shouldSnap = false
    private var hideWorkItem: DispatchWorkItem?
    private let feedbackGenerator = UISelectionFeedbackGenerator()

    private let thumbSize = CGSize(width: 40, height: 48)
    private let edgeMargin: CGFloat = 4
    private let trackMargin: CGFloat = 8
    private let hideDelay: TimeInterval = 1.5

    init(configure: TLDateScrubberConfigure) {
        self.configure = configure
        self.formatter = DateFormatter()
        self.formatter.locale = configure.locale
        self.formatter.calendar = configure.calendar
        self.formatter.setLocalizedDateFormatFromTemplate(configure.dateFormatTemplate)
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        hideWorkItem?.cancel()
    }

    private func setupViews() {
        backgroundColor = .clear
        alpha = isPersistent ? 1 : 0

        thumbView.backgroundColor = configure.thumbColor ?? .secondarySystemBackground
        thumbView.layer.cornerRadius = thumbSize.width / 2
        thumbView.layer.shadowColor = UIColor.black.cgColor
        thumbView.layer.shadowOpacity = 0.2
        thumbView.layer.shadowRadius = 3
        thumbView.layer.shadowOffset = CGSize(width: 0, height: 1)
        thumbView.isAccessibilityElement = true
        thumbView.accessibilityTraits = .adjustable
        thumbView.accessibilityLabel = configure.accessibilityLabel
        thumbView.onIncrement = { [weak self] in self?.moveByMonth(forward: true) }
        thumbView.onDecrement = { [weak self] in self?.moveByMonth(forward: false) }
        thumbView.valueProvider = { [weak self] in self?.currentLabel() }
        addSubview(thumbView)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        thumbIconView.image = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: symbolConfig)
        thumbIconView.tintColor = configure.thumbIconColor ?? .label
        thumbIconView.contentMode = .center
        thumbView.addSubview(thumbIconView)

        bubbleLabel.font = .preferredFont(forTextStyle: .subheadline)
        bubbleLabel.adjustsFontForContentSizeCategory = true
        bubbleLabel.textColor = configure.labelTextColor ?? .systemBackground
        bubbleLabel.backgroundColor = configure.labelBackgroundColor ?? UIColor.label.withAlphaComponent(0.85)
        bubbleLabel.layer.masksToBounds = true
        bubbleLabel.alpha = 0
        bubbleLabel.isAccessibilityElement = false
        addSubview(bubbleLabel)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        thumbView.addGestureRecognizer(pan)

        NotificationCenter.default.addObserver(self, selector: #selector(voiceOverStatusChanged),
                                               name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
    }

    /// Starts following `scrollView`'s offset and content size.
    func attach(to scrollView: UIScrollView) {
        self.scrollView = scrollView
        observations = [
            scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
                self?.scrollViewDidScroll(scrollView)
            },
            scrollView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
                self?.updateAvailability()
            }
        ]
    }

    // MARK: - Visibility

    private var isPersistent: Bool {
        return configure.alwaysVisible || UIAccessibility.isVoiceOverRunning
    }

    private var isAvailable: Bool {
        guard let scrollView = scrollView, scrollView.bounds.height > 0 else { return false }
        return scrollView.contentSize.height >= scrollView.bounds.height * configure.minimumContentScreens
            && navigatorProvider?() != nil
    }

    private func updateAvailability() {
        let available = isAvailable
        thumbView.isHidden = !available
        if !available {
            alpha = 0
        } else if isPersistent {
            alpha = 1
        }
        setNeedsLayout()
    }

    @objc private func voiceOverStatusChanged() {
        updateAvailability()
        if !isPersistent && !isScrubbing {
            scheduleHide()
        }
    }

    private func show() {
        hideWorkItem?.cancel()
        guard alpha < 1 else { return }
        UIView.animate(withDuration: 0.15) { self.alpha = 1 }
    }

    private func scheduleHide() {
        hideWorkItem?.cancel()
        guard !isPersistent else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isScrubbing else { return }
            UIView.animate(withDuration: 0.3) { self.alpha = 0 }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay, execute: workItem)
    }

    // MARK: - Hit Testing

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard alpha > 0.01, !thumbView.isHidden else { return nil }
        // Enlarge the touch target to at least 44pt on each side.
        let touchArea = thumbView.frame.insetBy(dx: -8, dy: -4)
        return touchArea.contains(point) ? thumbView : nil
    }

    // MARK: - Layout

    private var isRightToLeft: Bool {
        return effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    /// The vertical range the thumb's center can travel.
    private var trackRange: ClosedRange<CGFloat> {
        let insets = scrollView?.adjustedContentInset ?? .zero
        let top = insets.top + trackMargin + thumbSize.height / 2
        let bottom = bounds.height - insets.bottom - trackMargin - thumbSize.height / 2
        return top...max(top, bottom)
    }

    private func thumbX() -> CGFloat {
        return isRightToLeft ? edgeMargin : bounds.width - edgeMargin - thumbSize.width
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !isScrubbing, let scrollView = scrollView {
            thumbCenterY = centerY(forFraction: scrollFraction(of: scrollView))
        }
        layoutThumbAndBubble()
    }

    private func layoutThumbAndBubble() {
        thumbView.frame = CGRect(x: thumbX(), y: thumbCenterY - thumbSize.height / 2,
                                 width: thumbSize.width, height: thumbSize.height)
        thumbIconView.frame = thumbView.bounds
        let size = bubbleLabel.intrinsicContentSize
        bubbleLabel.layer.cornerRadius = size.height / 2
        let x = isRightToLeft ? thumbView.frame.maxX + 12 : thumbView.frame.minX - 12 - size.width
        bubbleLabel.frame = CGRect(x: x, y: thumbCenterY - size.height / 2, width: size.width, height: size.height)
    }

    // MARK: - Scroll <-> Fraction

    private func offsetRange(of scrollView: UIScrollView) -> ClosedRange<CGFloat> {
        let insets = scrollView.adjustedContentInset
        let minOffset = -insets.top
        let maxOffset = scrollView.contentSize.height + insets.bottom - scrollView.bounds.height
        return minOffset...max(minOffset, maxOffset)
    }

    private func scrollFraction(of scrollView: UIScrollView) -> CGFloat {
        let range = offsetRange(of: scrollView)
        let length = range.upperBound - range.lowerBound
        guard length > 0 else { return 0 }
        return min(max((scrollView.contentOffset.y - range.lowerBound) / length, 0), 1)
    }

    private func centerY(forFraction fraction: CGFloat) -> CGFloat {
        let range = trackRange
        return range.lowerBound + (range.upperBound - range.lowerBound) * fraction
    }

    private func fraction(forCenterY y: CGFloat) -> CGFloat {
        let range = trackRange
        let length = range.upperBound - range.lowerBound
        guard length > 0 else { return 0 }
        return min(max((y - range.lowerBound) / length, 0), 1)
    }

    private func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isScrubbing else { return }
        thumbCenterY = centerY(forFraction: scrollFraction(of: scrollView))
        layoutThumbAndBubble()
        guard isAvailable else { return }
        if scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating {
            show()
            scheduleHide()
        }
    }

    // MARK: - Scrubbing

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        switch gesture.state {
        case .began:
            guard let navigator = navigatorProvider?() else { return }
            isScrubbing = true
            grabOffset = location.y - thumbCenterY
            shouldSnap = configure.snapToMonth && navigator.monthSpan() >= configure.minimumMonthsForSnapping
            lastLabel = nil
            scrollView?.setContentOffset(scrollView?.contentOffset ?? .zero, animated: false) // stop deceleration
            feedbackGenerator.prepare()
            show()
            if configure.showsYearMarks {
                showYearMarks(navigator: navigator)
            }
            scrub(toCenterY: location.y - grabOffset)
            UIView.animate(withDuration: 0.15) { self.bubbleLabel.alpha = 1 }
        case .changed:
            guard isScrubbing else { return }
            scrub(toCenterY: location.y - grabOffset)
        case .ended, .cancelled, .failed:
            guard isScrubbing else { return }
            isScrubbing = false
            UIView.animate(withDuration: 0.2) {
                self.bubbleLabel.alpha = 0
                self.yearLabels.forEach { $0.alpha = 0 }
            }
            setNeedsLayout()
            scheduleHide()
        default:
            break
        }
    }

    private func scrub(toCenterY y: CGFloat) {
        guard let navigator = navigatorProvider?(), navigator.count > 0, let scrollView = scrollView else { return }
        let range = trackRange
        thumbCenterY = min(max(y, range.lowerBound), range.upperBound)
        let fraction = self.fraction(forCenterY: thumbCenterY)

        let date: Date
        if shouldSnap {
            let index = Int((CGFloat(navigator.count - 1) * fraction).rounded())
            date = navigator.date(at: index)
            if let monthStart = navigator.firstIndex(ofMonthContaining: date) {
                scrollToAssetIndex?(monthStart)
            }
        } else {
            let offsets = offsetRange(of: scrollView)
            let offset = offsets.lowerBound + (offsets.upperBound - offsets.lowerBound) * fraction
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: offset), animated: false)
            // Lay out first so the visible items reflect the new offset, not the previous one.
            scrollView.layoutIfNeeded()
            date = navigator.date(at: topAssetIndex?() ?? 0)
        }
        updateBubble(date: date)
        layoutThumbAndBubble()
    }

    private func updateBubble(date: Date) {
        guard date != .distantPast else { return }
        let label = formatter.string(from: date)
        if label != lastLabel {
            if lastLabel != nil, configure.hapticFeedback {
                feedbackGenerator.selectionChanged()
                feedbackGenerator.prepare()
            }
            lastLabel = label
            bubbleLabel.text = label
        }
    }

    private func showYearMarks(navigator: TLAssetDateNavigator) {
        yearLabels.forEach { $0.removeFromSuperview() }
        yearLabels.removeAll()
        guard let scrollView = scrollView as? UICollectionView, navigator.count > 1 else { return }
        let offsets = offsetRange(of: scrollView)
        let length = offsets.upperBound - offsets.lowerBound
        guard length > 0 else { return }
        var lastY = -CGFloat.greatestFiniteMagnitude
        let minimumSpacing: CGFloat = 24
        for mark in navigator.yearStarts() {
            // Place each mark where the thumb would be when that year's first asset is at the top.
            guard let indexPath = indexPathForAssetIndex?(mark.index),
                  let attributes = scrollView.layoutAttributesForItem(at: indexPath) else { continue }
            let offset = attributes.frame.minY - scrollView.adjustedContentInset.top
            let fraction = min(max((offset - offsets.lowerBound) / length, 0), 1)
            let y = centerY(forFraction: fraction)
            guard y - lastY >= minimumSpacing else { continue }
            lastY = y
            let label = TLPaddingLabel()
            label.insets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
            label.font = .preferredFont(forTextStyle: .caption1)
            label.textColor = .secondaryLabel
            label.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
            label.layer.masksToBounds = true
            label.text = "\(mark.year)"
            label.isAccessibilityElement = false
            let size = label.intrinsicContentSize
            label.layer.cornerRadius = size.height / 2
            let x = isRightToLeft ? thumbX() + thumbSize.width + 4 : thumbX() - 4 - size.width
            label.frame = CGRect(x: x, y: y - size.height / 2, width: size.width, height: size.height)
            label.alpha = 0
            insertSubview(label, belowSubview: bubbleLabel)
            yearLabels.append(label)
        }
        UIView.animate(withDuration: 0.15) { self.yearLabels.forEach { $0.alpha = 1 } }
    }

    // MARK: - Accessibility

    private func currentLabel() -> String? {
        guard let navigator = navigatorProvider?(), navigator.count > 0 else { return nil }
        let date = navigator.date(at: topAssetIndex?() ?? 0)
        return date == .distantPast ? nil : formatter.string(from: date)
    }

    private func moveByMonth(forward: Bool) {
        guard let navigator = navigatorProvider?(), navigator.count > 0 else { return }
        let current = topAssetIndex?() ?? 0
        let target = forward ? navigator.nextMonthStart(after: current) : navigator.previousMonthStart(before: current)
        guard let index = target else { return }
        scrollToAssetIndex?(index)
        setNeedsLayout()
    }
}

/// The scrubber thumb, adjustable with VoiceOver swipes (one month per step).
final class TLDateScrubberThumbView: UIView {
    var onIncrement: (() -> Void)?
    var onDecrement: (() -> Void)?
    var valueProvider: (() -> String?)?

    override var accessibilityValue: String? {
        get { return valueProvider?() }
        set { }
    }

    override func accessibilityIncrement() {
        onIncrement?()
    }

    override func accessibilityDecrement() {
        onDecrement?()
    }
}

final class TLPaddingLabel: UILabel {
    var insets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}
