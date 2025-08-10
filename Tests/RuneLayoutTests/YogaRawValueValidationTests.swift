import Testing
@testable import RuneLayout

struct YogaRawValueValidationTests {
    @Test("YogaWrapper mappings use expected raw values")
    func yogaEnumRawValuesMatch() {
        // This tests our wrapper constants, not yoga.core symbols, so it remains stable
        // even if yoga's public symbol names vary. It still guards raw-value skew.
        // FlexDirection
        #expect(YogaFlexDirection.row.yogaValue.rawValue == YogaFlexDirection.create(rawValue: 2).rawValue)
        #expect(YogaFlexDirection.column.yogaValue.rawValue == YogaFlexDirection.create(rawValue: 0).rawValue)
        #expect(YogaFlexDirection.rowReverse.yogaValue.rawValue == YogaFlexDirection.create(rawValue: 3).rawValue)
        #expect(YogaFlexDirection.columnReverse.yogaValue.rawValue == YogaFlexDirection.create(rawValue: 1).rawValue)

        // Justify
        #expect(JustifyContent.flexStart.yogaValue.rawValue == JustifyContent.create(rawValue: 0).rawValue)
        #expect(JustifyContent.center.yogaValue.rawValue == JustifyContent.create(rawValue: 1).rawValue)
        #expect(JustifyContent.flexEnd.yogaValue.rawValue == JustifyContent.create(rawValue: 2).rawValue)
        #expect(JustifyContent.spaceBetween.yogaValue.rawValue == JustifyContent.create(rawValue: 3).rawValue)
        #expect(JustifyContent.spaceAround.yogaValue.rawValue == JustifyContent.create(rawValue: 4).rawValue)
        #expect(JustifyContent.spaceEvenly.yogaValue.rawValue == JustifyContent.create(rawValue: 5).rawValue)

        // Align
        #expect(AlignItems.flexStart.yogaValue.rawValue == AlignItems.create(rawValue: 1).rawValue)
        #expect(AlignItems.center.yogaValue.rawValue == AlignItems.create(rawValue: 2).rawValue)
        #expect(AlignItems.flexEnd.yogaValue.rawValue == AlignItems.create(rawValue: 3).rawValue)
        #expect(AlignItems.stretch.yogaValue.rawValue == AlignItems.create(rawValue: 4).rawValue)
        #expect(AlignItems.baseline.yogaValue.rawValue == AlignItems.create(rawValue: 5).rawValue)

        // AlignSelf
        #expect(AlignSelf.auto.yogaValue.rawValue == AlignSelf.create(rawValue: 0).rawValue)
        #expect(AlignSelf.flexStart.yogaValue.rawValue == AlignSelf.create(rawValue: 1).rawValue)
        #expect(AlignSelf.center.yogaValue.rawValue == AlignSelf.create(rawValue: 2).rawValue)
        #expect(AlignSelf.flexEnd.yogaValue.rawValue == AlignSelf.create(rawValue: 3).rawValue)
        #expect(AlignSelf.stretch.yogaValue.rawValue == AlignSelf.create(rawValue: 4).rawValue)
        #expect(AlignSelf.baseline.yogaValue.rawValue == AlignSelf.create(rawValue: 5).rawValue)

        // Wrap
        #expect(FlexWrap.noWrap.yogaValue.rawValue == FlexWrap.create(rawValue: 0).rawValue)
        #expect(FlexWrap.wrap.yogaValue.rawValue == FlexWrap.create(rawValue: 1).rawValue)
        #expect(FlexWrap.wrapReverse.yogaValue.rawValue == FlexWrap.create(rawValue: 2).rawValue)

        // Edge/Gutter can be added similarly if we expose create(rawValue:) for tests.
    }
}

