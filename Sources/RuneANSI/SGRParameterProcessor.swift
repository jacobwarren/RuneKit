/// SGR parameter processing for ANSI escape sequences
///
/// This module handles the complex logic of interpreting and generating
/// SGR (Select Graphic Rendition) parameter codes for text styling.

/// Processor for SGR (Select Graphic Rendition) parameters
///
/// This struct handles the conversion between SGR parameter codes and
/// text attributes, managing the complex state transitions and color handling.
struct SGRParameterProcessor {
    /// Apply SGR parameters to text attributes
    ///
    /// This method interprets SGR parameter codes and updates the text attributes
    /// accordingly. It handles all standard SGR codes including colors and styles.
    ///
    /// - Parameters:
    ///   - parameters: SGR parameter codes
    ///   - attributes: Current text attributes to modify
    /// - Returns: Updated text attributes
    func applySGRParameters(_ parameters: [Int], to attributes: TextAttributes) -> TextAttributes {
        var newAttributes = attributes
        var i = 0

        while i < parameters.count {
            let param = parameters[i]
            let result = applySingleSGRParameter(param, parameters: parameters, index: i, to: newAttributes)
            newAttributes = result.attributes
            i = result.nextIndex
        }

        return newAttributes
    }

    /// Apply a single SGR parameter to text attributes
    ///
    /// - Parameters:
    ///   - param: The SGR parameter to apply
    ///   - parameters: Full parameter array (for extended color parsing)
    ///   - index: Current index in parameters array
    ///   - attributes: Current text attributes
    /// - Returns: Updated attributes and next index to process
    private func applySingleSGRParameter(
        _ param: Int,
        parameters: [Int],
        index: Int,
        to attributes: TextAttributes,
    ) -> (attributes: TextAttributes, nextIndex: Int) {
        var newAttributes = attributes
        var nextIndex = index + 1

        // Handle style parameters
        if let styleResult = applyStyleParameter(param, to: newAttributes) {
            return (attributes: styleResult, nextIndex: nextIndex)
        }

        // Handle color parameters
        if let colorResult = applyColorParameter(param, parameters: parameters, index: index, to: newAttributes) {
            return colorResult
        }

        // Unknown parameter, ignore
        return (attributes: newAttributes, nextIndex: nextIndex)
    }

    /// Apply style-related SGR parameters
    ///
    /// - Parameters:
    ///   - param: The SGR parameter
    ///   - attributes: Current attributes
    /// - Returns: Updated attributes if parameter was handled, nil otherwise
    private func applyStyleParameter(_ param: Int, to attributes: TextAttributes) -> TextAttributes? {
        // Handle reset first
        if param == 0 {
            return TextAttributes() // Reset all attributes
        }

        // Handle style enable parameters
        if let enabledAttributes = applyStyleEnable(param, to: attributes) {
            return enabledAttributes
        }

        // Handle style disable parameters
        if let disabledAttributes = applyStyleDisable(param, to: attributes) {
            return disabledAttributes
        }

        return nil // Not a style parameter
    }

    /// Apply style enable SGR parameters
    /// - Parameters:
    ///   - param: The SGR parameter
    ///   - attributes: Current attributes
    /// - Returns: Updated attributes if parameter was handled, nil otherwise
    private func applyStyleEnable(_ param: Int, to attributes: TextAttributes) -> TextAttributes? {
        var newAttributes = attributes

        switch param {
        case 1:
            newAttributes.bold = true
        case 2:
            newAttributes.dim = true
        case 3:
            newAttributes.italic = true
        case 4:
            newAttributes.underline = true
        case 7:
            newAttributes.inverse = true
        case 9:
            newAttributes.strikethrough = true
        default:
            return nil
        }

        return newAttributes
    }

    /// Apply style disable SGR parameters
    /// - Parameters:
    ///   - param: The SGR parameter
    ///   - attributes: Current attributes
    /// - Returns: Updated attributes if parameter was handled, nil otherwise
    private func applyStyleDisable(_ param: Int, to attributes: TextAttributes) -> TextAttributes? {
        var newAttributes = attributes

        switch param {
        case 22:
            newAttributes.bold = false
            newAttributes.dim = false
        case 23:
            newAttributes.italic = false
        case 24:
            newAttributes.underline = false
        case 27:
            newAttributes.inverse = false
        case 29:
            newAttributes.strikethrough = false
        default:
            return nil
        }

        return newAttributes
    }

    /// Apply color-related SGR parameters
    ///
    /// - Parameters:
    ///   - param: The SGR parameter
    ///   - parameters: Full parameter array
    ///   - index: Current index
    ///   - attributes: Current attributes
    /// - Returns: Updated attributes and next index if handled, nil otherwise
    private func applyColorParameter(
        _ param: Int,
        parameters: [Int],
        index: Int,
        to attributes: TextAttributes,
    ) -> (attributes: TextAttributes, nextIndex: Int)? {
        // Handle foreground colors
        if let result = applyForegroundColor(param, parameters: parameters, index: index, to: attributes) {
            return result
        }

        // Handle background colors
        if let result = applyBackgroundColor(param, parameters: parameters, index: index, to: attributes) {
            return result
        }

        return nil // Not a color parameter
    }

    /// Apply foreground color SGR parameters
    /// - Parameters:
    ///   - param: The SGR parameter
    ///   - parameters: Full parameter array
    ///   - index: Current index
    ///   - attributes: Current attributes
    /// - Returns: Updated attributes and next index if handled, nil otherwise
    private func applyForegroundColor(
        _ param: Int,
        parameters: [Int],
        index: Int,
        to attributes: TextAttributes,
    ) -> (attributes: TextAttributes, nextIndex: Int)? {
        var newAttributes = attributes
        var nextIndex = index + 1

        switch param {
        case 30 ... 37:
            newAttributes.color = basicColor(from: param - 30)
        case 38:
            if let color = parseExtendedColor(parameters, startingAt: index) {
                newAttributes.color = color.color
                nextIndex = color.nextIndex
            }
        case 39:
            newAttributes.color = nil
        case 90 ... 97:
            newAttributes.color = brightColor(from: param - 90)
        default:
            return nil
        }

        return (attributes: newAttributes, nextIndex: nextIndex)
    }

    /// Apply background color SGR parameters
    /// - Parameters:
    ///   - param: The SGR parameter
    ///   - parameters: Full parameter array
    ///   - index: Current index
    ///   - attributes: Current attributes
    /// - Returns: Updated attributes and next index if handled, nil otherwise
    private func applyBackgroundColor(
        _ param: Int,
        parameters: [Int],
        index: Int,
        to attributes: TextAttributes,
    ) -> (attributes: TextAttributes, nextIndex: Int)? {
        var newAttributes = attributes
        var nextIndex = index + 1

        switch param {
        case 40 ... 47:
            newAttributes.backgroundColor = basicColor(from: param - 40)
        case 48:
            if let color = parseExtendedColor(parameters, startingAt: index) {
                newAttributes.backgroundColor = color.color
                nextIndex = color.nextIndex
            }
        case 49:
            newAttributes.backgroundColor = nil
        case 100 ... 107:
            newAttributes.backgroundColor = brightColor(from: param - 100)
        default:
            return nil
        }

        return (attributes: newAttributes, nextIndex: nextIndex)
    }

    /// Parse extended color sequences (256-color or RGB)
    ///
    /// - Parameters:
    ///   - parameters: Full SGR parameter array
    ///   - startIndex: Index of the 38 or 48 parameter
    /// - Returns: Parsed color and next index, or nil if invalid
    private func parseExtendedColor(
        _ parameters: [Int],
        startingAt startIndex: Int,
    ) -> (color: ANSIColor, nextIndex: Int)? {
        guard startIndex + 1 < parameters.count else { return nil }

        let colorType = parameters[startIndex + 1]

        switch colorType {
        case 5:
            // 256-color palette
            guard startIndex + 2 < parameters.count else { return nil }
            let colorIndex = parameters[startIndex + 2]
            return (color: .color256(colorIndex), nextIndex: startIndex + 3)

        case 2:
            // RGB color
            guard startIndex + 4 < parameters.count else { return nil }
            let red = parameters[startIndex + 2]
            let green = parameters[startIndex + 3]
            let blue = parameters[startIndex + 4]
            return (color: .rgb(red, green, blue), nextIndex: startIndex + 5)

        default:
            return nil
        }
    }

    /// Get basic ANSI color from color index
    ///
    /// - Parameter index: Color index (0-7)
    /// - Returns: Corresponding ANSIColor
    private func basicColor(from index: Int) -> ANSIColor {
        switch index {
        case 0: .black
        case 1: .red
        case 2: .green
        case 3: .yellow
        case 4: .blue
        case 5: .magenta
        case 6: .cyan
        case 7: .white
        default: .white
        }
    }

    /// Get bright ANSI color from color index
    ///
    /// - Parameter index: Color index (0-7)
    /// - Returns: Corresponding bright ANSIColor
    private func brightColor(from index: Int) -> ANSIColor {
        switch index {
        case 0: .brightBlack
        case 1: .brightRed
        case 2: .brightGreen
        case 3: .brightYellow
        case 4: .brightBlue
        case 5: .brightMagenta
        case 6: .brightCyan
        case 7: .brightWhite
        default: .brightWhite
        }
    }
}
