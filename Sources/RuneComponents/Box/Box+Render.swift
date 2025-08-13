import RuneANSI
import RuneLayout
import RuneUnicode

// Rendering for Box extracted into an extension (no behavior change)
public extension Box {
    func render(in rect: FlexLayout.Rect) -> [String] {
        guard rect.height > 0, rect.width > 0 else { return [] }

        let borderWidth = borderStyle != .none ? 1 : 0
        let contentX = borderWidth + Int(paddingLeft)
        let contentY = borderWidth + Int(paddingTop)
        let contentWidth = max(0, rect.width - 2 * borderWidth - Int(paddingLeft) - Int(paddingRight))
        let contentHeight = max(0, rect.height - 2 * borderWidth - Int(paddingTop) - Int(paddingBottom))

        var lines = initialLines(rect: rect, hasBorder: borderStyle != .none)
        if borderStyle != .none {
            BoxRenderer.renderBorder(into: &lines, rect: rect, style: borderStyle, color: borderColor)
        }

        if contentWidth > 0, contentHeight > 0 {
            let allChildren: [Component] = children.isEmpty ? (child.map { [$0] } ?? []) : children
            if !allChildren.isEmpty {
                if allChildren.count == 1 {
                    let ctx = RenderContext(rect: rect, contentWidth: contentWidth, contentX: contentX, contentY: contentY)
                    renderSingleChild(allChildren[0], ctx: ctx, lines: &lines)
                } else {
                    let ctx = RenderContext(rect: rect, contentWidth: contentWidth, contentX: contentX, contentY: contentY)
                    renderMultipleChildren(allChildren, ctx: ctx, lines: &lines)
                }
            }
        }

        if borderStyle != .none, rect.height >= 2, rect.width >= 2 {
            ensureVerticalBorders(rect: rect, lines: &lines)
        }
        return lines
    }

    // MARK: - Helpers extracted to reduce complexity

    private func initialLines(rect: FlexLayout.Rect, hasBorder: Bool) -> [String] {
        if hasBorder {
            return Array(repeating: String(repeating: " ", count: rect.width), count: rect.height)
        } else {
            return Array(repeating: "", count: rect.height)
        }
    }

    private func renderSingleChild(
        _ childComponent: Component,
        ctx: RenderContext,
        lines: inout [String]
    ) {
        let childRect = FlexLayout.Rect(
            x: 0,
            y: 0,
            width: ctx.contentWidth,
            height: max(0, ctx.rect.height - 2 * (borderStyle != .none ? 1 : 0) - Int(paddingTop) - Int(paddingBottom))
        )
        let identitySuffix = (childComponent as? ComponentIdentifiable)?.componentIdentity.map { "child#" + $0 } ?? "child#0"
        let childPath = [RuntimeStateContext.currentPath, "Box", identitySuffix].joined(separator: "/")
        RuntimeStateContext.record(childPath)
        let childLines = RuntimeStateContext.$currentPath.withValue(childPath) {
            childComponent.render(in: childRect)
        }
        for (lineIndex, childLine) in childLines.enumerated() {
            let lineY = ctx.contentY + lineIndex
            if lineY >= 0, lineY < lines.count {
                if borderStyle != .none {
                    renderChildLineWithinBorder(childLine, rect: ctx.rect, contentX: ctx.contentX, lineY: lineY, into: &lines)
                } else {
                    let padding = String(repeating: " ", count: ctx.contentX)
                    let content = ANSISafeTruncation.truncateToDisplayWidth(childLine, maxWidth: ctx.contentWidth)
                    lines[lineY] = padding + content
                }
            }
        }
    }

    private func renderMultipleChildren(
        _ allChildren: [Component],
        ctx: RenderContext,
        lines: inout [String]
    ) {
        let layout = calculateLayout(in: ctx.rect)
        for (index, childComponent) in allChildren.enumerated() where index < layout.childRects.count {
            let childRect = layout.childRects[index]
            let identitySuffix = (childComponent as? ComponentIdentifiable)?.componentIdentity.map { "child#" + $0 } ?? "child#\(index)"
            let childPath = [RuntimeStateContext.currentPath, "Box", identitySuffix].joined(separator: "/")
            RuntimeStateContext.record(childPath)
            let childLines = RuntimeStateContext.$currentPath.withValue(childPath) {
                childComponent.render(in: childRect)
            }
            for (lineIndex, childLine) in childLines.enumerated() {
                let lineY = ctx.contentY + childRect.y + lineIndex
                if lineY >= 0, lineY < lines.count {
                    let startX = ctx.contentX + childRect.x
                    if startX < ctx.rect.width {
                        if borderStyle != .none {
                            let availableWidth = max(0, ctx.contentWidth - childRect.x)
                            let args = OverlayArgs(lineY: lineY, startX: startX, availableWidth: availableWidth)
                            renderChildLineWithinBorderOverlay(childLine, ctx: ctx, args: args, into: &lines)
                        } else {
                            let padding = String(repeating: " ", count: startX)
                            let availableWidth = max(0, ctx.contentWidth - childRect.x)
                            let truncatedContent = ANSISafeTruncation.truncateToDisplayWidth(childLine, maxWidth: availableWidth)
                            lines[lineY] = padding + truncatedContent
                        }
                    }
                }
            }
        }
    }

    private func renderChildLineWithinBorder(_ childLine: String, rect: FlexLayout.Rect, contentX: Int, lineY: Int, into lines: inout [String]) {
        renderChildLineWithinBorder(childLine, ctx: RenderContext(rect: rect, contentWidth: 0, contentX: contentX, contentY: lineY), lines: &lines)
    }

    private func renderChildLineWithinBorder(_ childLine: String, ctx: RenderContext, lines: inout [String]) {
        let truncatedContent = ANSISafeTruncation.truncateToDisplayWidth(childLine, maxWidth: max(0, ctx.rect.width - 2))
        let contentStartInMiddle = ctx.contentX - 1
        let spacesBefore = String(repeating: " ", count: contentStartInMiddle)
        let borderChars = BoxRenderer.getBorderChars(for: borderStyle)
        let contentWithPadding = spacesBefore + truncatedContent
        let middleTargetWidth = ctx.rect.width - 2
        let currentWidthIgnoringANSI = ANSISafeTruncation.displayWidthIgnoringANSI(contentWithPadding)
        let spacesNeeded = max(0, middleTargetWidth - currentWidthIgnoringANSI)
        let newMiddle = contentWithPadding + String(repeating: " ", count: spacesNeeded)
        let leftBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
        let rightBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
        let bgOn = (backgroundColor?.backgroundSequence ?? "")
        let bgOff = backgroundColor != nil ? "\u{001B}[0m" : ""
        let middleAdjusted = BoxRenderer.adjustContentToDisplayWidth(newMiddle, targetWidth: middleTargetWidth)
        lines[ctx.contentY] = leftBorder + bgOn + middleAdjusted + bgOff + rightBorder
    }

    private struct RenderContext { let rect: FlexLayout.Rect; let contentWidth: Int; let contentX: Int; let contentY: Int }
    private struct OverlayArgs { let lineY: Int; let startX: Int; let availableWidth: Int }
    // Overlay content inside bordered box without overwriting borders; ANSI-safe and width-aware
    private func renderChildLineWithinBorderOverlay(_ childLine: String, ctx: RenderContext, args: OverlayArgs, into lines: inout [String]) {
        let middleAreaWidth = ctx.rect.width - 2
        let tokenizer = ANSITokenizer()
        let converter = ANSISpanConverter()
        let styledLine = converter.tokensToStyledText(tokenizer.tokenize(lines[args.lineY]))
        let interiorStyled = styledLine.sliceByDisplayColumns(from: 1, to: 1 + middleAreaWidth)
        let existingMiddle = tokenizer.encode(converter.styledTextToTokens(interiorStyled))
        func padToDisplayWidth(_ content: String, to width: Int) -> String {
            let current = ANSISafeTruncation.displayWidthIgnoringANSI(content)
            return content + String(repeating: " ", count: max(0, width - current))
        }
        let middleBuf = padToDisplayWidth(existingMiddle, to: middleAreaWidth)
        let truncatedContent = ANSISafeTruncation.truncateToDisplayWidth(childLine, maxWidth: args.availableWidth)
        let leftSlice = ANSISafeTruncation.truncateToDisplayWidth(middleBuf, maxWidth: max(0, args.startX - 1))
        let rightStart = max(0, (args.startX - 1) + ANSISafeTruncation.displayWidthIgnoringANSI(truncatedContent))
        let middleStyled = converter.tokensToStyledText(tokenizer.tokenize(middleBuf))
        let rightStyledSlice = middleStyled.sliceByDisplayColumns(from: rightStart, to: middleAreaWidth)
        let rightSlice = tokenizer.encode(converter.styledTextToTokens(rightStyledSlice))
        let newMiddle = leftSlice + truncatedContent + rightSlice
        let borderChars = BoxRenderer.getBorderChars(for: borderStyle)
        let leftBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
        let rightBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
        let bgOn = (backgroundColor?.backgroundSequence ?? "")
        let bgOff = backgroundColor != nil ? "\u{001B}[0m" : ""
        let middleAdjusted = BoxRenderer.adjustContentToDisplayWidth(newMiddle, targetWidth: middleAreaWidth)
        lines[args.lineY] = leftBorder + bgOn + middleAdjusted + bgOff + rightBorder
    }
    private func ensureVerticalBorders(rect: FlexLayout.Rect, lines: inout [String]) {
        let borderChars = BoxRenderer.getBorderChars(for: borderStyle)
        let leftBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
        let rightBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
        let bgOn = (backgroundColor?.backgroundSequence ?? "")
        let bgOff = backgroundColor != nil ? "\u{001B}[0m" : ""
        let middleAreaWidth = rect.width - 2
        let tokenizer = ANSITokenizer()
        let converter = ANSISpanConverter()
        for y in 1 ..< (rect.height - 1) where y < lines.count {
            let styled = converter.tokensToStyledText(tokenizer.tokenize(lines[y]))
            let interiorStyled = styled.sliceByDisplayColumns(from: 1, to: 1 + middleAreaWidth)
            let interior = tokenizer.encode(converter.styledTextToTokens(interiorStyled))
            let middleAdjusted = BoxRenderer.adjustContentToDisplayWidth(interior, targetWidth: middleAreaWidth)
            lines[y] = leftBorder + bgOn + middleAdjusted + bgOff + rightBorder
        }
    }
}
