//
//  DateNavigationExampleViewController.swift
//  TLPhotoPicker_Example
//
//  Created by wade.hawk on 2026. 11. 15..
//  Copyright © 2026년 wade.hawk. All rights reserved.
//

import UIKit
import TLPhotoPicker

/// Lets you pick a date and scrubber options, then opens the picker with them.
///
/// Tip: seed the simulator with dated photos first.
/// `swift Scripts/seed-dated-photos.swift <output-dir>` then `xcrun simctl addmedia booted <output-dir>/*.jpg`
class DateNavigationExampleViewController: UIViewController {

    /// Called with the configured picker; the presenter sets delegates and presents it.
    var onOpenPicker: ((TLPhotosPickerConfigure) -> Void)?

    private let datePicker = UIDatePicker()
    private let initialDateSwitch = UISwitch()
    private let scrubberSwitch = UISwitch()
    private let snapSwitch = UISwitch()
    private let yearMarksSwitch = UISwitch()
    private let alwaysVisibleSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Date Navigation"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))

        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        datePicker.date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        }

        initialDateSwitch.isOn = true
        scrubberSwitch.isOn = true
        snapSwitch.isOn = true
        yearMarksSwitch.isOn = true
        alwaysVisibleSwitch.isOn = false
        scrubberSwitch.addTarget(self, action: #selector(updateEnabledState), for: .valueChanged)
        initialDateSwitch.addTarget(self, action: #selector(updateEnabledState), for: .valueChanged)

        let openButton = UIButton(type: .system)
        openButton.setTitle("Open Picker", for: .normal)
        openButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        openButton.addTarget(self, action: #selector(openPicker), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            datePicker,
            row("Scroll to this date on open", initialDateSwitch),
            row("Date scrubber", scrubberSwitch),
            row("Snap to month", snapSwitch),
            row("Year marks", yearMarksSwitch),
            row("Always visible", alwaysVisibleSwitch),
            openButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(24, after: alwaysVisibleSwitch.superview ?? stack)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16)
        ])
        updateEnabledState()
    }

    private func row(_ title: String, _ toggle: UISwitch) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [label, toggle])
        row.alignment = .center
        row.spacing = 8
        return row
    }

    @objc private func updateEnabledState() {
        datePicker.isEnabled = initialDateSwitch.isOn
        [snapSwitch, yearMarksSwitch, alwaysVisibleSwitch].forEach { $0.isEnabled = scrubberSwitch.isOn }
    }

    @objc private func openPicker() {
        var scrubber = TLDateScrubberConfigure()
        scrubber.snapToMonth = snapSwitch.isOn
        scrubber.showsYearMarks = yearMarksSwitch.isOn
        scrubber.alwaysVisible = alwaysVisibleSwitch.isOn

        let configure = TLPhotosPickerConfigure()
            .numberOfColumns(3)
            .singleSelection(true)
            .maxSelection(1)
            .initialScrollDate(initialDateSwitch.isOn ? datePicker.date : nil)
            .dateScrubber(scrubberSwitch.isOn ? scrubber : nil)
        onOpenPicker?(configure)
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
