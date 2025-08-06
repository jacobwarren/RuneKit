import Testing
@testable import RuneLayout
@testable import RuneComponents

/// Tests for advanced flex layout features (RUNE-28)
/// Covers min/max constraints, wrapping, and overflow clipping
struct FlexAdvancedLayoutTests {
    
    // MARK: - Min/Max Constraint Tests
    
    @Test("Min width constraint prevents shrinking below minimum")
    func minWidthConstraintPreventsOverShrinking() {
        // Arrange
        let child1 = Box(
            width: .points(100),
            height: .points(20),
            flexShrink: 1,
            minWidth: .points(60),
            child: Text("Child 1")
        )

        let child2 = Box(
            width: .points(100),
            height: .points(20),
            flexShrink: 1,
            minWidth: .points(40),
            child: Text("Child 2")
        )
        
        let container = Box(
            flexDirection: .row,
            width: .points(120),
            height: .points(50),
            children: [child1, child2]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 120, height: 50)
        
        // Act
        let layout = container.calculateLayout(in: containerRect)
        
        // Assert
        // Total width: 120, initial child widths: 100 + 100 = 200
        // Overflow: 80, but child1 can only shrink to 60, child2 to 40
        // Child 1: min(100 - proportional_shrink, 60) = 60
        // Child 2: min(100 - proportional_shrink, 40) = 40
        #expect(layout.childRects.count == 2, "Should have 2 child rects")
        
        let child1Rect = layout.childRects[0]
        let child2Rect = layout.childRects[1]
        
        #expect(child1Rect.width >= 60, "Child 1 should respect min width")
        #expect(child2Rect.width >= 40, "Child 2 should respect min width")
    }
    
    @Test("Max width constraint prevents growing beyond maximum")
    func maxWidthConstraintPreventsOverGrowing() {
        // Arrange
        let child1 = Box(
            width: .points(50),
            height: .points(20),
            flexGrow: 1,
            maxWidth: .points(80),
            child: Text("Child 1")
        )

        let child2 = Box(
            width: .points(50),
            height: .points(20),
            flexGrow: 1,
            maxWidth: .points(120),
            child: Text("Child 2")
        )
        
        let container = Box(
            flexDirection: .row,
            width: .points(300),
            height: .points(50),
            children: [child1, child2]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 300, height: 50)
        
        // Act
        let layout = container.calculateLayout(in: containerRect)
        
        // Assert
        // Total width: 300, initial child widths: 50 + 50 = 100
        // Extra space: 200, but child1 can only grow to 80, child2 to 120
        #expect(layout.childRects.count == 2, "Should have 2 child rects")
        
        let child1Rect = layout.childRects[0]
        let child2Rect = layout.childRects[1]
        
        #expect(child1Rect.width <= 80, "Child 1 should respect max width")
        #expect(child2Rect.width <= 120, "Child 2 should respect max width")
    }
    
    @Test("Min and max height constraints work in column direction")
    func minMaxHeightConstraintsInColumn() {
        // Arrange
        let child1 = Box(
            width: .points(50),
            height: .points(30),
            flexGrow: 1,
            minHeight: .points(20),
            maxHeight: .points(60),
            child: Text("Child 1")
        )

        let child2 = Box(
            width: .points(50),
            height: .points(30),
            flexGrow: 2,
            minHeight: .points(40),
            maxHeight: .points(100),
            child: Text("Child 2")
        )
        
        let container = Box(
            flexDirection: .column,
            width: .points(100),
            height: .points(200),
            children: [child1, child2]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 100, height: 200)
        
        // Act
        let layout = container.calculateLayout(in: containerRect)
        
        // Assert
        #expect(layout.childRects.count == 2, "Should have 2 child rects")
        
        let child1Rect = layout.childRects[0]
        let child2Rect = layout.childRects[1]
        
        #expect(child1Rect.height >= 20, "Child 1 should respect min height")
        #expect(child1Rect.height <= 60, "Child 1 should respect max height")
        #expect(child2Rect.height >= 40, "Child 2 should respect min height")
        #expect(child2Rect.height <= 100, "Child 2 should respect max height")
    }
    
    // MARK: - Flex Wrap Tests
    
    @Test("Flex wrap creates new line when content overflows")
    func flexWrapCreatesNewLineOnOverflow() {
        // Arrange
        let child1 = Box(
            width: .points(80),
            height: .points(20),
            child: Text("Child 1")
        )
        
        let child2 = Box(
            width: .points(80),
            height: .points(20),
            child: Text("Child 2")
        )
        
        let child3 = Box(
            width: .points(80),
            height: .points(20),
            child: Text("Child 3")
        )
        
        let container = Box(
            flexDirection: .row,
            width: .points(150),
            height: .points(100),
            flexWrap: .wrap,
            children: [child1, child2, child3]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 150, height: 100)
        
        // Act
        let layout = container.calculateLayout(in: containerRect)
        
        // Assert
        // First line: child1 (80) + child2 (80) = 160 > 150, so child2 wraps
        // Line 1: child1 at (0,0)
        // Line 2: child2 at (0,20)
        // Line 3: child3 at (0,40) (since child2 + child3 = 160 > 150)
        #expect(layout.childRects.count == 3, "Should have 3 child rects")

        let child1Rect = layout.childRects[0]
        let child2Rect = layout.childRects[1]
        let child3Rect = layout.childRects[2]

        #expect(child1Rect.y == 0, "Child 1 should be on first line")
        #expect(child2Rect.y > child1Rect.y, "Child 2 should wrap to next line")
        #expect(child3Rect.y > child2Rect.y, "Child 3 should wrap to next line (since child2 + child3 > container width)")
    }
    
    @Test("Flex wrap respects emoji-safe width boundaries")
    func flexWrapRespectsEmojiSafeWidths() {
        // Arrange
        let emojiChild = Box(
            width: .points(4), // 2 emoji characters = 4 terminal columns
            height: .points(20),
            child: Text("👨‍👩‍👧‍👦🎉") // Family emoji + party emoji
        )
        
        let textChild = Box(
            width: .points(10),
            height: .points(20),
            child: Text("Hello")
        )
        
        let container = Box(
            flexDirection: .row,
            width: .points(12), // Just enough for emoji but not both
            height: .points(100),
            flexWrap: .wrap,
            children: [emojiChild, textChild]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 12, height: 100)
        
        // Act
        let layout = container.calculateLayout(in: containerRect)
        
        // Assert
        // Emoji child (4) + text child (10) = 14 > 12, so text wraps
        #expect(layout.childRects.count == 2, "Should have 2 child rects")
        
        let emojiRect = layout.childRects[0]
        let textRect = layout.childRects[1]
        
        #expect(emojiRect.y == 0, "Emoji child should be on first line")
        #expect(textRect.y > emojiRect.y, "Text child should wrap to next line")
        #expect(emojiRect.width == 4, "Emoji should maintain proper width")
    }
    
    // MARK: - Overflow Clipping Tests
    
    @Test("Overflow is clipped at wrap boundaries")
    func overflowIsClippedAtWrapBoundaries() {
        // Arrange
        let wideChild = Box(
            width: .points(200), // Much wider than container
            height: .points(20),
            child: Text("This is a very long text that should be clipped")
        )
        
        let container = Box(
            flexDirection: .row,
            width: .points(100),
            height: .points(50),
            flexWrap: .wrap,
            children: [wideChild]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 100, height: 50)
        
        // Act
        let layout = container.calculateLayout(in: containerRect)
        
        // Assert
        #expect(layout.childRects.count == 1, "Should have 1 child rect")
        
        let childRect = layout.childRects[0]
        
        // Child should be clipped to container width
        #expect(childRect.width <= 100, "Child width should be clipped to container")
        #expect(childRect.x + childRect.width <= layout.contentRect.x + layout.contentRect.width, 
               "Child should not extend beyond container bounds")
    }
    
    @Test("Vertical overflow is clipped in wrapped layout")
    func verticalOverflowIsClippedInWrappedLayout() {
        // Arrange
        let tallChild = Box(
            width: .points(50),
            height: .points(200), // Much taller than container
            child: Text("Tall content")
        )
        
        let container = Box(
            flexDirection: .row,
            width: .points(100),
            height: .points(50),
            flexWrap: .wrap,
            children: [tallChild]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 100, height: 50)
        
        // Act
        let layout = container.calculateLayout(in: containerRect)
        
        // Assert
        #expect(layout.childRects.count == 1, "Should have 1 child rect")
        
        let childRect = layout.childRects[0]
        
        // Child should be clipped to container height
        #expect(childRect.height <= 50, "Child height should be clipped to container")
        #expect(childRect.y + childRect.height <= layout.contentRect.y + layout.contentRect.height,
               "Child should not extend beyond container bounds")
    }
}
