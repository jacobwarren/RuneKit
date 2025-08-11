import RuneANSI
import RuneLayout

public extension Box {
    /// Convenience initializer for simple padding
    init(
        border: BorderStyle = .none,
        padding: Float,
        child: Component? = nil,
    ) {
        self.init(
            border: border,
            borderColor: nil,
            backgroundColor: nil,
            paddingTop: padding,
            paddingRight: padding,
            paddingBottom: padding,
            paddingLeft: padding,
            child: child,
        )
    }

    /// Convenience initializer for horizontal and vertical padding
    init(
        border: BorderStyle = .none,
        paddingHorizontal: Float = 0,
        paddingVertical: Float = 0,
        child: Component? = nil,
    ) {
        self.init(
            border: border,
            borderColor: nil,
            backgroundColor: nil,
            paddingTop: paddingVertical,
            paddingRight: paddingHorizontal,
            paddingBottom: paddingVertical,
            paddingLeft: paddingHorizontal,
            child: child,
        )
    }

    /// Convenience initializer for flex row layout
    static func row(
        justifyContent: JustifyContent = .flexStart,
        alignItems: AlignItems = .stretch,
        alignSelf: AlignSelf = .auto,
        gap: Float = 0,
        child: Component? = nil,
    ) -> Box {
        Box(
            borderColor: nil,
            backgroundColor: nil,
            flexDirection: .row,
            justifyContent: justifyContent,
            alignItems: alignItems,
            alignSelf: alignSelf,
            columnGap: gap,
            child: child,
        )
    }

    /// Convenience initializer for flex column layout
    static func column(
        justifyContent: JustifyContent = .flexStart,
        alignItems: AlignItems = .stretch,
        alignSelf: AlignSelf = .auto,
        gap: Float = 0,
        child: Component? = nil,
    ) -> Box {
        Box(
            borderColor: nil,
            backgroundColor: nil,
            flexDirection: .column,
            justifyContent: justifyContent,
            alignItems: alignItems,
            alignSelf: alignSelf,
            rowGap: gap,
            child: child,
        )
    }
}
