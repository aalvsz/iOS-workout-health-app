import UIKit
import SwiftUI

@MainActor
class ReportGenerator {
    static let shared = ReportGenerator()

    private init() {}

    func generateReport(from viewModel: AnalyticsDashboardViewModel) throws -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - 2 * margin

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            var yOffset: CGFloat = margin

            // Title
            yOffset = drawTitle("FitPulse Progress Report", at: yOffset, in: context, width: contentWidth, margin: margin)
            yOffset = drawSubtitle("Generated \(Date().formatted(date: .long, time: .omitted))", at: yOffset, in: context, width: contentWidth, margin: margin)
            yOffset += 20

            // Weight Summary
            yOffset = drawSectionHeader("Weight Progress", at: yOffset, in: context, margin: margin)
            if let latest = viewModel.weightData.last, let first = viewModel.weightData.first {
                let change = latest.value - first.value
                let changeStr = String(format: "%+.1f kg", change)
                yOffset = drawKeyValue("Current Weight", value: String(format: "%.1f kg", latest.value), at: yOffset, in: context, margin: margin, width: contentWidth)
                yOffset = drawKeyValue("Change", value: changeStr, at: yOffset, in: context, margin: margin, width: contentWidth)
                yOffset = drawKeyValue("Data Points", value: "\(viewModel.weightData.count)", at: yOffset, in: context, margin: margin, width: contentWidth)
            } else {
                yOffset = drawBody("No weight data available.", at: yOffset, in: context, margin: margin, width: contentWidth)
            }
            yOffset += 16

            // Training Summary
            yOffset = drawSectionHeader("Training Summary", at: yOffset, in: context, margin: margin)
            yOffset = drawKeyValue("Total Workout Time", value: "\(viewModel.totalWorkoutMinutes) min", at: yOffset, in: context, margin: margin, width: contentWidth)
            yOffset = drawKeyValue("Weekly Data Points", value: "\(viewModel.workoutVolumeData.count)", at: yOffset, in: context, margin: margin, width: contentWidth)
            yOffset += 16

            // Check page break
            if yOffset > pageHeight - 200 {
                context.beginPage()
                yOffset = margin
            }

            // Nutrition Adherence
            yOffset = drawSectionHeader("Nutrition Adherence", at: yOffset, in: context, margin: margin)
            yOffset = drawKeyValue("Average Adherence", value: "\(viewModel.averageNutritionAdherence)%", at: yOffset, in: context, margin: margin, width: contentWidth)
            yOffset = drawKeyValue("Days Tracked", value: "\(viewModel.nutritionAdherenceData.count)", at: yOffset, in: context, margin: margin, width: contentWidth)
            yOffset += 16

            // Recovery
            yOffset = drawSectionHeader("Recovery Scores", at: yOffset, in: context, margin: margin)
            yOffset = drawKeyValue("Average Score", value: "\(viewModel.averageRecoveryScore) / 100", at: yOffset, in: context, margin: margin, width: contentWidth)
            if let insight = viewModel.recoveryInsight {
                yOffset += 8
                yOffset = drawBody("AI Insight: \(insight)", at: yOffset, in: context, margin: margin, width: contentWidth)
            }
            yOffset += 16

            // Footer
            if yOffset > pageHeight - 80 {
                context.beginPage()
                yOffset = margin
            }
            drawFooter(in: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }

        return data
    }

    // MARK: - Drawing Helpers

    private func drawTitle(_ text: String, at y: CGFloat, in context: UIGraphicsPDFRendererContext, width: CGFloat, margin: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let rect = CGRect(x: margin, y: y, width: width, height: 40)
        str.draw(in: rect)
        return y + 34
    }

    private func drawSubtitle(_ text: String, at y: CGFloat, in context: UIGraphicsPDFRendererContext, width: CGFloat, margin: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let rect = CGRect(x: margin, y: y, width: width, height: 20)
        str.draw(in: rect)
        return y + 20
    }

    private func drawSectionHeader(_ text: String, at y: CGFloat, in context: UIGraphicsPDFRendererContext, margin: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.systemBlue
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let rect = CGRect(x: margin, y: y, width: 400, height: 24)
        str.draw(in: rect)

        // Underline
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y + 22))
        path.addLine(to: CGPoint(x: margin + 200, y: y + 22))
        UIColor.systemBlue.withAlphaComponent(0.3).setStroke()
        path.lineWidth = 1
        path.stroke()

        return y + 30
    }

    private func drawKeyValue(_ key: String, value: String, at y: CGFloat, in context: UIGraphicsPDFRendererContext, margin: CGFloat, width: CGFloat) -> CGFloat {
        let keyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]

        let keyStr = NSAttributedString(string: key, attributes: keyAttrs)
        keyStr.draw(in: CGRect(x: margin + 8, y: y, width: width / 2, height: 18))

        let valueStr = NSAttributedString(string: value, attributes: valueAttrs)
        valueStr.draw(in: CGRect(x: margin + width / 2, y: y, width: width / 2, height: 18))

        return y + 20
    }

    private func drawBody(_ text: String, at y: CGFloat, in context: UIGraphicsPDFRendererContext, margin: CGFloat, width: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let boundingRect = str.boundingRect(with: CGSize(width: width - 16, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
        str.draw(in: CGRect(x: margin + 8, y: y, width: width - 16, height: boundingRect.height + 4))
        return y + boundingRect.height + 8
    }

    private func drawFooter(in context: UIGraphicsPDFRendererContext, pageWidth: CGFloat, pageHeight: CGFloat, margin: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.lightGray
        ]
        let str = NSAttributedString(string: "Generated by FitPulse", attributes: attrs)
        str.draw(in: CGRect(x: margin, y: pageHeight - 40, width: 200, height: 16))
    }
}
