import SwiftUI

/// Renders a wrapping set of keyword chips respecting dynamic type and accessibility settings.
struct FlexibleKeywordGrid: View {
    let keywords: [String: Int]

    var body: some View {
        FlowLayout(alignment: .leading) {
            ForEach(Array(keywords.sorted { $0.value > $1.value }), id: \.key) { keyword, weight in
                Text(keyword.capitalized)
                    .fontWeight(weight > 3 ? .bold : .regular)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    .overlay(Capsule().stroke(Color.accentColor.opacity(0.4)))
            }
        }
    }
}

/// Generic flow layout to wrap content items across lines.
struct FlowLayout<Content: View>: View {
    let alignment: HorizontalAlignment
    let content: Content

    init(alignment: HorizontalAlignment, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(minHeight: 0)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            content
                .alignmentGuide(.leading) { dimension in
                    if abs(width - dimension.width) > geometry.size.width {
                        width = 0
                        height -= dimension.height
                    }
                    let result = width
                    width -= dimension.width
                    return result
                }
                .alignmentGuide(.top) { dimension in
                    let result = height
                    height -= dimension.height
                    return result
                }
        }
    }
}
