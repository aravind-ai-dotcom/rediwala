import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// UPI QR compatible with GPay, PhonePe, Paytm, and other UPI apps.
struct VendorUPIQRPayload: Equatable {
    var upiID: String
    var payeeName: String
    var amountRupees: Int?
    var note: String?

    /// Standard NPCI UPI deep-link format scanned by GPay and other UPI apps.
    var upiURI: String {
        var parts = [
            "upi://pay",
            "pa=\(upiID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? upiID)",
            "pn=\(payeeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? payeeName)",
            "cu=INR"
        ]
        if let amountRupees, amountRupees > 0 {
            parts.append("am=\(String(format: "%.2f", Double(amountRupees)))")
        }
        if let note, !note.isEmpty {
            let encoded = note.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? note
            parts.append("tn=\(encoded)")
        }
        return parts.joined(separator: "?")
    }
}

enum VendorQRGenerator {
    static func upiImage(for payload: VendorUPIQRPayload, size: CGFloat = 240) -> UIImage? {
        qrImage(from: payload.upiURI, size: size)
    }

    static func qrImage(from string: String, size: CGFloat = 240) -> UIImage? {
        let data = Data(string.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
