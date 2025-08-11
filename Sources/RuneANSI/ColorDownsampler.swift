/// Maps ANSIColor to a given terminal profile, downsampling if necessary.
struct ColorDownsampler {
    let profile: TerminalProfile

    func map(_ color: ANSIColor) -> ANSIColor? {
        switch profile {
        case .trueColor:
            color
        case .xterm256:
            switch color {
            case let .rgb(red, green, blue):
                nearest256(red: red, green: green, blue: blue)
            default:
                color
            }
        case .basic16:
            switch color {
            case let .rgb(red, green, blue):
                nearestBasic(red: red, green: green, blue: blue)
            case let .color256(idx):
                map256ToBasic(idx)
            default:
                color
            }
        case .noColor:
            nil
        }
    }

    // Very simple approximations for now (can be refined later without API changes)
    private func nearest256(red: Int, green: Int, blue: Int) -> ANSIColor {
        // Map to 6x6x6 cube (216 colors) ignoring grayscale for simplicity
        func clamp(_ value: Int) -> Int { max(0, min(255, value)) }
        let rClamped = clamp(red), gClamped = clamp(green), bClamped = clamp(blue)
        func quantize(_ value: Int) -> Int { Int((Double(value) / 255.0 * 5.0).rounded()) }
        let rQuant = quantize(rClamped), gQuant = quantize(gClamped), bQuant = quantize(bClamped)
        let idx = 16 + (36 * rQuant) + (6 * gQuant) + bQuant
        return .color256(idx)
    }

    private func nearestBasic(red: Int, green: Int, blue: Int) -> ANSIColor {
        // Map to one of the 8 basic colors using simple luminance and hue buckets
        // Basic palette: black, red, green, yellow, blue, magenta, cyan, white
        let red = max(0, min(255, red)), green = max(0, min(255, green)), blue = max(0, min(255, blue))
        let maxComponent = max(red, max(green, blue))
        let luminance = (red + green + blue) / 3
        if maxComponent < 30 { return .black }
        if luminance > 220 { return .white }
        if red >= green, red >= blue { return green > 128 ? .yellow : .red }
        if green >= red, green >= blue { return blue > 128 ? .cyan : .green }
        if blue >= red, blue >= green { return red > 128 ? .magenta : .blue }
        return .white
    }

    private func map256ToBasic(_ idx: Int) -> ANSIColor {
        // Use index buckets to pick a basic color; simple mapping
        if idx < 16 {
            switch idx {
            case 0: return .black
            case 1: return .red
            case 2: return .green
            case 3: return .yellow
            case 4: return .blue
            case 5: return .magenta
            case 6: return .cyan
            case 7: return .white
            default: return .white
            }
        } else {
            // Map cube to nearest basic using cube position
            let cubeIdx = idx - 16
            let rIndex = cubeIdx / 36
            let gIndex = (cubeIdx % 36) / 6
            let bIndex = cubeIdx % 6
            let red = rIndex * 51, green = gIndex * 51, blue = bIndex * 51
            return nearestBasic(red: red, green: green, blue: blue)
        }
    }
}
