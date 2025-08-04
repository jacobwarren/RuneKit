/// SGR parameter generation for ANSI escape sequences
///
/// This module handles the conversion from text attributes back to
/// SGR parameter codes for generating ANSI escape sequences.

/// Generator for SGR (Select Graphic Rendition) parameters
///
/// This struct handles the conversion from text attributes to SGR parameter codes,
/// generating the appropriate ANSI escape sequence parameters for styling.
struct SGRParameterGenerator {
    /// Convert text attributes to SGR parameters
    ///
    /// This method generates the appropriate SGR parameter codes for the given
    /// text attributes, handling all supported styling options.
    ///
    /// - Parameter attributes: The text attributes to convert
    /// - Returns: Array of SGR parameter codes
    func attributesToSGRParameters(_ attributes: TextAttributes) -> [Int] {
        var parameters: [Int] = []

        // Add style parameters
        if attributes.bold {
            parameters.append(1)
        }
        if attributes.dim {
            parameters.append(2)
        }
        if attributes.italic {
            parameters.append(3)
        }
        if attributes.underline {
            parameters.append(4)
        }
        if attributes.inverse {
            parameters.append(7)
        }
        if attributes.strikethrough {
            parameters.append(9)
        }

        // Add color parameters
        if let color = attributes.color {
            parameters.append(contentsOf: colorToSGRParameters(color, isBackground: false))
        }
        if let backgroundColor = attributes.backgroundColor {
            parameters.append(contentsOf: colorToSGRParameters(backgroundColor, isBackground: true))
        }

        return parameters
    }

    /// Convert color to SGR parameters
    ///
    /// - Parameters:
    ///   - color: The color to convert
    ///   - isBackground: Whether this is a background color
    /// - Returns: Array of SGR parameters for the color
    private func colorToSGRParameters(_ color: ANSIColor, isBackground: Bool) -> [Int] {
        switch color {
        case .black, .red, .green, .yellow, .blue, .magenta, .cyan, .white:
            basicColorToSGR(color, isBackground: isBackground)
        case .brightBlack, .brightRed, .brightGreen, .brightYellow, .brightBlue, .brightMagenta, .brightCyan,
             .brightWhite:
            brightColorToSGR(color, isBackground: isBackground)
        case let .color256(index):
            [isBackground ? 48 : 38, 5, index]
        case let .rgb(red, green, blue):
            [isBackground ? 48 : 38, 2, red, green, blue]
        }
    }

    /// Convert basic color to SGR parameters
    ///
    /// - Parameters:
    ///   - color: Basic ANSI color
    ///   - isBackground: Whether this is a background color
    /// - Returns: SGR parameters for basic color
    private func basicColorToSGR(_ color: ANSIColor, isBackground: Bool) -> [Int] {
        let baseOffset = isBackground ? 40 : 30
        switch color {
        case .black: return [baseOffset + 0]
        case .red: return [baseOffset + 1]
        case .green: return [baseOffset + 2]
        case .yellow: return [baseOffset + 3]
        case .blue: return [baseOffset + 4]
        case .magenta: return [baseOffset + 5]
        case .cyan: return [baseOffset + 6]
        case .white: return [baseOffset + 7]
        default: return [baseOffset + 7] // Default to white
        }
    }

    /// Convert bright color to SGR parameters
    ///
    /// - Parameters:
    ///   - color: Bright ANSI color
    ///   - isBackground: Whether this is a background color
    /// - Returns: SGR parameters for bright color
    private func brightColorToSGR(_ color: ANSIColor, isBackground: Bool) -> [Int] {
        let brightOffset = isBackground ? 100 : 90
        switch color {
        case .brightBlack: return [brightOffset + 0]
        case .brightRed: return [brightOffset + 1]
        case .brightGreen: return [brightOffset + 2]
        case .brightYellow: return [brightOffset + 3]
        case .brightBlue: return [brightOffset + 4]
        case .brightMagenta: return [brightOffset + 5]
        case .brightCyan: return [brightOffset + 6]
        case .brightWhite: return [brightOffset + 7]
        default: return [brightOffset + 7] // Default to bright white
        }
    }
}
