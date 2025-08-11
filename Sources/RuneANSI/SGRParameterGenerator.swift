/// SGR parameter generation for ANSI escape sequences
///
/// This module handles the conversion from text attributes back to
/// SGR parameter codes for generating ANSI escape sequences.

/// Generator for SGR (Select Graphic Rendition) parameters
///
/// This struct handles the conversion from text attributes to SGR parameter codes,
/// generating the appropriate ANSI escape sequence parameters for styling.
struct SGRParameterGenerator {
    var profile: TerminalProfile = .trueColor

    // MARK: - Helpers (extracted to reduce complexity)
    /// Build SGR effect parameters (bold, dim, italic, underline, inverse, strikethrough)
    func effectParameters(from attrs: TextAttributes) -> [Int] {
        var params: [Int] = []
        if attrs.bold { params.append(1) }
        if attrs.dim { params.append(2) }
        if attrs.italic { params.append(3) }
        if attrs.underline { params.append(4) }
        if attrs.inverse { params.append(7) }
        if attrs.strikethrough { params.append(9) }
        return params
    }

    /// Determine if a code is a color-related SGR code
    func isColorCode(_ code: Int) -> Bool {
        code == 38 || code == 48 || (30...37).contains(code) || (40...47).contains(code) ||
            (90...97).contains(code) || (100...107).contains(code)
    }

    ///
    /// - Parameter attributes: The text attributes to convert
    /// - Returns: Array of SGR parameter codes
    func attributesToSGRParameters(_ attributes: TextAttributes) -> [Int] {
        var parameters: [Int] = []

        // Effects (bold/italic/underline/etc.) first
        parameters.append(contentsOf: effectParameters(from: attributes))

        // Colors next
        if let color = attributes.color {
            parameters.append(contentsOf: colorToSGRParameters(color, isBackground: false))
        }
        if let backgroundColor = attributes.backgroundColor {
            parameters.append(contentsOf: colorToSGRParameters(backgroundColor, isBackground: true))
        }

        if profile == .noColor {
            // Strip any color-related codes; keep effects
            parameters.removeAll(where: isColorCode)
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
        guard let mappedColor = mapColorForProfile(color) else { return [] }
        return parameters(for: mappedColor, isBackground: isBackground)
    }

    private func mapColorForProfile(_ color: ANSIColor) -> ANSIColor? {
        switch profile {
        case .trueColor:
            return color
        case .xterm256:
            if case let .rgb(red, green, blue) = color {
                return ColorDownsampler(profile: .xterm256).map(.rgb(red, green, blue))
            }
            return color
        case .basic16:
            switch color {
            case let .rgb(red, green, blue):
                return ColorDownsampler(profile: .basic16).map(.rgb(red, green, blue))
            case let .color256(index):
                return ColorDownsampler(profile: .basic16).map(.color256(index))
            default:
                return color
            }
        case .noColor:
            return nil
        }
    }

    private func parameters(for color: ANSIColor, isBackground: Bool) -> [Int] {
        switch color {
        case .black, .red, .green, .yellow, .blue, .magenta, .cyan, .white:
            return basicColorToSGR(color, isBackground: isBackground)
        case .brightBlack, .brightRed, .brightGreen, .brightYellow, .brightBlue, .brightMagenta, .brightCyan, .brightWhite:
            return brightColorToSGR(color, isBackground: isBackground)
        case let .color256(index):
            return color256Params(index, isBackground)
        case let .rgb(red, green, blue):
            return rgbParams(red, green, blue, isBackground)
        }
    }

    /// Convert basic color to SGR parameters
    ///

    /// Build 256-color parameters (38/48 ; 5 ; idx)
    private func color256Params(_ index: Int, _ isBackground: Bool) -> [Int] {
        guard (0...255).contains(index) else { return [] }
        return [isBackground ? 48 : 38, 5, index]
    }

    /// Build truecolor parameters (38/48 ; 2 ; r ; g ; b)
    private func rgbParams(_ red: Int, _ green: Int, _ blue: Int, _ isBackground: Bool) -> [Int] {
        guard (0...255).contains(red), (0...255).contains(green), (0...255).contains(blue) else { return [] }
        return [isBackground ? 48 : 38, 2, red, green, blue]
    }

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
