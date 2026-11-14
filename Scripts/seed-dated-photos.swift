#!/usr/bin/env swift
// Generates JPEGs with EXIF capture dates spread over past months, for trying the
// date navigation example in the simulator. Each photo shows its date.
//
//   swift Scripts/seed-dated-photos.swift /tmp/tl-seed 24
//   xcrun simctl addmedia booted /tmp/tl-seed/*.jpg
//
// Arguments: output directory, number of months (default 24). One photo every 36 hours.

import Foundation
import ImageIO
import CoreGraphics
import CoreText
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    print("usage: swift seed-dated-photos.swift <output-dir> [months]")
    exit(1)
}
let outputDirectory = URL(fileURLWithPath: arguments[1])
let months = arguments.count >= 3 ? Int(arguments[2]) ?? 24 : 24
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let calendar = Calendar.current
let exifFormatter = DateFormatter()
exifFormatter.locale = Locale(identifier: "en_US_POSIX")
exifFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
let labelFormatter = DateFormatter()
labelFormatter.locale = Locale(identifier: "en_US_POSIX")
labelFormatter.dateFormat = "yyyy-MM-dd"

let end = Date()
let start = calendar.date(byAdding: .month, value: -months, to: end)!
var date = end
var count = 0
while date > start {
    let size = 300
    let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    // A different hue per month makes month boundaries easy to see while scrubbing.
    let hue = CGFloat(calendar.component(.month, from: date)) / 12
    context.setFillColor(CGColor(red: 0.3 + 0.6 * hue, green: 0.5, blue: 0.9 - 0.6 * hue, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 40, nil)
    let attributes = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: CGColor(gray: 0, alpha: 1)] as CFDictionary
    let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, labelFormatter.string(from: date) as CFString, attributes))
    context.textPosition = CGPoint(x: 18, y: 130)
    CTLineDraw(line, context)

    let url = outputDirectory.appendingPathComponent(String(format: "seed-%04d.jpg", count))
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    let exif: [CFString: Any] = [
        kCGImagePropertyExifDateTimeOriginal: exifFormatter.string(from: date),
        kCGImagePropertyExifDateTimeDigitized: exifFormatter.string(from: date)
    ]
    CGImageDestinationAddImage(destination, context.makeImage()!, [kCGImagePropertyExifDictionary: exif] as CFDictionary)
    CGImageDestinationFinalize(destination)
    count += 1
    date = date.addingTimeInterval(-36 * 3600)
}
print("Wrote \(count) photos to \(outputDirectory.path)")
