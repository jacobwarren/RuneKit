import RuneLayout
import RuneANSI
import RuneUnicode

// Rendering for Box extracted into an extension (no behavior change)
extension Box {
    public func render(in rect: FlexLayout.Rect) -> [String] {
        guard rect.height > 0, rect.width > 0 else {
            return []
        }

        // Calculate content area (accounting for border and padding)
        let borderWidth = borderStyle != .none ? 1 : 0
        let contentX = borderWidth + Int(paddingLeft)
        let contentY = borderWidth + Int(paddingTop)
        let contentWidth = max(0, rect.width - 2 * borderWidth - Int(paddingLeft) - Int(paddingRight))
        let contentHeight = max(0, rect.height - 2 * borderWidth - Int(paddingTop) - Int(paddingBottom))

        // Start with empty lines - only fill with spaces if we have borders
        var lines: [String]
        if borderStyle != .none {
            lines = Array(repeating: String(repeating: " ", count: rect.width), count: rect.height)
            // Render border first so content can be placed within it (apply borderColor if provided)
            BoxRenderer.renderBorder(into: &lines, rect: rect, style: borderStyle, color: borderColor)
        } else {
            lines = Array(repeating: "", count: rect.height)
        }

        // Render children content if present
        if contentWidth > 0 && contentHeight > 0 {
            // Get all children (either from children array or single child)
            let allChildren: [Component] = children.isEmpty ? (child.map { [$0] } ?? []) : children

            if !allChildren.isEmpty {
                if allChildren.count == 1 {
                    // For single child, render directly with simple positioning
                    let childComponent = allChildren[0]
                    let childRect = FlexLayout.Rect(x: 0, y: 0, width: contentWidth, height: contentHeight)

                    // Extend identity path for this child based on identity if provided
                    let identitySuffix: String
                    if let ident = (childComponent as? ComponentIdentifiable)?.componentIdentity { identitySuffix = "child#" + ident } else { identitySuffix = "child#0" }
                    let childPath = [RuntimeStateContext.currentPath, "Box", identitySuffix].joined(separator: "/")
                    RuntimeStateContext.record(childPath)
                    let childLines = RuntimeStateContext.$currentPath.withValue(childPath) {
                        childComponent.render(in: childRect)
                    }

                    // Place child content within the content area
                    for (lineIndex, childLine) in childLines.enumerated() {
                        let lineY = contentY + lineIndex
                        if lineY >= 0 && lineY < lines.count {
                            if borderStyle != .none {
                                // For bordered boxes: place content within the content area, never overwrite borders
                                // The line structure is: │<content area>│
                                // contentX is the start position within the content area (after left border + padding)

                                // Truncate content to fit within the available content width
                                let truncatedContent: String
                                truncatedContent = ANSISafeTruncation.truncateToDisplayWidth(childLine, maxWidth: contentWidth)

                                // Build the content with padding
                                let contentStartInMiddle = contentX - 1  // contentX is relative to full line, adjust for middle area
                                let spacesBefore = String(repeating: " ", count: contentStartInMiddle)

                                // Get the correct border characters
                                let borderChars = BoxRenderer.getBorderChars(for: borderStyle)

                                // ANSI-aware padding to ensure final display width matches tests
                                let contentWithPadding = spacesBefore + truncatedContent
                                let middleTargetWidth = rect.width - 2
                                let currentWidthIgnoringANSI = ANSISafeTruncation.displayWidthIgnoringANSI(contentWithPadding)
                                let spacesNeeded = max(0, middleTargetWidth - currentWidthIgnoringANSI)
                                let finalContent = contentWithPadding + String(repeating: " ", count: spacesNeeded)

                                // Apply background color within content area and colored vertical borders with minimal resets
                                let leftBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
                                let rightBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
                                let bgOn = (backgroundColor?.backgroundSequence ?? "")
                                let bgOff = backgroundColor != nil ? "\u{001B}[0m" : ""
                                lines[lineY] = leftBorder + bgOn + finalContent + bgOff + rightBorder
                            } else {
                                // Without borders, just place the content with appropriate padding
                                let startX = contentX
                                let padding = String(repeating: " ", count: startX)

                                // Use ANSI-aware truncation for content with ANSI codes
                                let content: String
                                content = ANSISafeTruncation.truncateToDisplayWidth(childLine, maxWidth: contentWidth)

                                lines[lineY] = padding + content
                            }
                        }
                    }
                } else {
                    // For multiple children, use layout calculation
                    let layout = calculateLayout(in: rect)

                    // Render each child in its calculated position
                    for (index, childComponent) in allChildren.enumerated() {
                        if index < layout.childRects.count {
                            let childRect = layout.childRects[index]

                            // Extend identity path for this child based on identity if provided
                            let identitySuffix: String
                            if let ident = (childComponent as? ComponentIdentifiable)?.componentIdentity { identitySuffix = "child#" + ident } else { identitySuffix = "child#\(index)" }
                            let childPath = [RuntimeStateContext.currentPath, "Box", identitySuffix].joined(separator: "/")
                            RuntimeStateContext.record(childPath)
                            let childLines = RuntimeStateContext.$currentPath.withValue(childPath) {
                                childComponent.render(in: childRect)
                            }

                            // Place child content within the content area
                            for (lineIndex, childLine) in childLines.enumerated() {
                                let lineY = contentY + childRect.y + lineIndex
                                if lineY >= 0 && lineY < lines.count {
                                    let startX = contentX + childRect.x
                                    if startX < rect.width {
                                        if borderStyle != .none {
                                            // Calculate available width for this child within the content area (in display columns)
                                            let availableWidth = max(0, contentWidth - childRect.x)

                                            // ANSI-aware slice of child content to fit available display columns
                                            let truncatedContent = ANSISafeTruncation.truncateToDisplayWidth(childLine, maxWidth: availableWidth)

                                            // Rebuild middle area by display columns to avoid corrupting ANSI and wide chars
                                            let middleAreaWidth = rect.width - 2
                                            // Extract existing interior (excluding left/right borders) ANSI-safely by display columns
                                            let tokenizer = ANSITokenizer()
                                            let converter = ANSISpanConverter()
                                            let styledLine = converter.tokensToStyledText(tokenizer.tokenize(lines[lineY]))
                                            let interiorStyled = styledLine.sliceByDisplayColumns(from: 1, to: 1 + middleAreaWidth)
                                            let existingMiddle = tokenizer.encode(converter.styledTextToTokens(interiorStyled))

                                            // Build a column-accurate buffer
                                            func padToDisplayWidth(_ s: String, to width: Int) -> String {
                                                let w = ANSISafeTruncation.displayWidthIgnoringANSI(s)
                                                return s + String(repeating: " ", count: max(0, width - w))
                                            }

                                            let middleBuf = padToDisplayWidth(existingMiddle, to: middleAreaWidth)

                                            // Insert the truncated content at the correct display column offset
                                            let leftSlice = ANSISafeTruncation.truncateToDisplayWidth(middleBuf, maxWidth: max(0, startX - 1))
                                            let rightStart = max(0, (startX - 1) + ANSISafeTruncation.displayWidthIgnoringANSI(truncatedContent))
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
                                            lines[lineY] = leftBorder + bgOn + middleAdjusted + bgOff + rightBorder
                                        } else {
                                            // Without borders, just place the content
                                            let padding = String(repeating: " ", count: startX)
                                            let availableWidth = max(0, contentWidth - childRect.x)

                                            let truncatedContent: String
                                            truncatedContent = ANSISafeTruncation.truncateToDisplayWidth(childLine, maxWidth: availableWidth)

                                            lines[lineY] = padding + truncatedContent
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Safety post-pass: ensure vertical borders are present on all interior lines
        if borderStyle != .none && rect.height >= 2 && rect.width >= 2 {
            let borderChars = BoxRenderer.getBorderChars(for: borderStyle)
            let leftBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
            let rightBorder = (borderColor?.foregroundSequence ?? "") + borderChars.vertical + (borderColor != nil ? "\u{001B}[0m" : "")
            let bgOn = (backgroundColor?.backgroundSequence ?? "")
            let bgOff = backgroundColor != nil ? "\u{001B}[0m" : ""
            let middleAreaWidth = rect.width - 2

            let tokenizer = ANSITokenizer()
            let converter = ANSISpanConverter()

            for y in 1..<(rect.height - 1) {
                guard y < lines.count else { continue }
                // Extract interior by display columns [1, 1+middleAreaWidth)
                let styled = converter.tokensToStyledText(tokenizer.tokenize(lines[y]))
                let interiorStyled = styled.sliceByDisplayColumns(from: 1, to: 1 + middleAreaWidth)
                let interior = tokenizer.encode(converter.styledTextToTokens(interiorStyled))
                let middleAdjusted = BoxRenderer.adjustContentToDisplayWidth(interior, targetWidth: middleAreaWidth)
                lines[y] = leftBorder + bgOn + middleAdjusted + bgOff + rightBorder
            }
        }

        return lines
    }
}

