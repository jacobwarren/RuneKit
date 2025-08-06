import Testing
@testable import RuneLayout
@testable import RuneComponents

/// Snapshot tests demonstrating complete flex layout functionality (RUNE-28)
/// These tests show real-world usage patterns and serve as documentation
struct FlexLayoutSnapshotTests {
    
    @Test("Snapshot: Complex dashboard layout with flex grow/shrink")
    func snapshotComplexDashboardLayout() {
        // Arrange - Create a dashboard-like layout
        let sidebar = Box(
            width: .points(20),
            height: .points(30),
            flexShrink: 0, // Don't shrink sidebar
            minWidth: .points(15),
            child: Text("Sidebar")
        )
        
        let mainContent = Box(
            height: .points(30),
            flexGrow: 1, // Take remaining space
            child: Text("Main Content Area")
        )
        
        let rightPanel = Box(
            width: .points(25),
            height: .points(30),
            flexShrink: 2, // Shrink faster than sidebar
            minWidth: .points(10),
            child: Text("Right Panel")
        )
        
        let dashboard = Box(
            flexDirection: .row,
            width: .points(100),
            height: .points(40),
            children: [sidebar, mainContent, rightPanel]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 100, height: 40)
        
        // Act
        let layout = dashboard.calculateLayout(in: containerRect)
        
        // Assert & Document
        print("\n=== Dashboard Layout Snapshot ===")
        print("Container: 100x40")
        print("Sidebar (flexShrink: 0, minWidth: 15): \(layout.childRects[0])")
        print("Main (flexGrow: 1): \(layout.childRects[1])")
        print("Right Panel (flexShrink: 2, minWidth: 10): \(layout.childRects[2])")
        
        // Verify layout behavior
        let sidebarRect = layout.childRects[0]
        let mainRect = layout.childRects[1]
        let rightRect = layout.childRects[2]
        
        #expect(sidebarRect.width >= 15, "Sidebar should respect min width")
        #expect(mainRect.width > 0, "Main content should get remaining space")
        #expect(rightRect.width >= 10, "Right panel should respect min width")
        #expect(sidebarRect.width + mainRect.width + rightRect.width <= 100, "Total width should not exceed container")
    }
    
    @Test("Snapshot: Responsive card grid with wrapping")
    func snapshotResponsiveCardGrid() {
        // Arrange - Create a responsive card grid
        let card1 = Box(
            width: .points(30),
            height: .points(20),
            flexShrink: 0, // Cards maintain size
            child: Text("Card 1")
        )
        
        let card2 = Box(
            width: .points(30),
            height: .points(20),
            flexShrink: 0,
            child: Text("Card 2")
        )
        
        let card3 = Box(
            width: .points(30),
            height: .points(20),
            flexShrink: 0,
            child: Text("Card 3")
        )
        
        let card4 = Box(
            width: .points(30),
            height: .points(20),
            flexShrink: 0,
            child: Text("Card 4")
        )
        
        let cardGrid = Box(
            flexDirection: .row,
            width: .points(80),
            height: .points(60),
            flexWrap: .wrap,
            children: [card1, card2, card3, card4]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 80, height: 60)
        
        // Act
        let layout = cardGrid.calculateLayout(in: containerRect)
        
        // Assert & Document
        print("\n=== Responsive Card Grid Snapshot ===")
        print("Container: 80x60, Card size: 30x20")
        print("Expected: 2 cards per row (30+30=60 < 80), 2 rows")
        
        for (index, cardRect) in layout.childRects.enumerated() {
            print("Card \(index + 1): \(cardRect)")
        }
        
        // Verify wrapping behavior
        let card1Rect = layout.childRects[0]
        let card2Rect = layout.childRects[1]
        let card3Rect = layout.childRects[2]
        let card4Rect = layout.childRects[3]
        
        // First row: card1 and card2
        #expect(card1Rect.y == card2Rect.y, "Card 1 and 2 should be on same row")
        #expect(card2Rect.x > card1Rect.x, "Card 2 should be to the right of card 1")
        
        // Second row: card3 and card4
        #expect(card3Rect.y > card1Rect.y, "Card 3 should be on next row")
        #expect(card4Rect.y == card3Rect.y, "Card 3 and 4 should be on same row")
        #expect(card4Rect.x > card3Rect.x, "Card 4 should be to the right of card 3")
    }
    
    @Test("Snapshot: Emoji-safe terminal layout")
    func snapshotEmojiSafeLayout() {
        // Arrange - Layout with emoji content
        let emojiHeader = Box(
            width: .points(8), // 4 emoji chars = 8 terminal columns
            height: .points(3),
            flexShrink: 0,
            child: Text("🎉🚀💻🎯") // Party, rocket, laptop, target
        )
        
        let textContent = Box(
            height: .points(3),
            flexGrow: 1,
            minWidth: .points(10),
            child: Text("Status: Ready")
        )
        
        let statusIcon = Box(
            width: .points(2), // 1 emoji = 2 columns
            height: .points(3),
            flexShrink: 0,
            child: Text("✅") // Check mark
        )
        
        let statusBar = Box(
            flexDirection: .row,
            width: .points(25),
            height: .points(5),
            flexWrap: .wrap,
            children: [emojiHeader, textContent, statusIcon]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 25, height: 5)
        
        // Act
        let layout = statusBar.calculateLayout(in: containerRect)
        
        // Assert & Document
        print("\n=== Emoji-Safe Layout Snapshot ===")
        print("Container: 25x5")
        print("Emoji header (8 cols): \(layout.childRects[0])")
        print("Text content (flexGrow: 1): \(layout.childRects[1])")
        print("Status icon (2 cols): \(layout.childRects[2])")
        
        let headerRect = layout.childRects[0]
        let contentRect = layout.childRects[1]
        let iconRect = layout.childRects[2]
        
        // Verify emoji-safe widths
        #expect(headerRect.width == 8, "Emoji header should maintain proper width")
        #expect(iconRect.width == 2, "Status icon should maintain proper width")
        #expect(contentRect.width >= 10, "Text content should respect min width")
        
        // Total should fit or wrap appropriately
        let totalWidth = headerRect.width + contentRect.width + iconRect.width
        if totalWidth <= 25 {
            // All on one line
            #expect(headerRect.y == contentRect.y && contentRect.y == iconRect.y, "All should be on same line")
        } else {
            // Should wrap appropriately
            print("Layout wrapped due to width constraints")
        }
    }
    
    @Test("Snapshot: Constrained layout with min/max bounds")
    func snapshotConstrainedLayout() {
        // Arrange - Layout with various constraints
        let flexibleColumn = Box(
            height: .points(25),
            flexGrow: 1,
            flexShrink: 1,
            minWidth: .points(20),
            maxWidth: .points(40),
            child: Text("Flexible Column")
        )
        
        let fixedColumn = Box(
            width: .points(30),
            height: .points(25),
            flexShrink: 0,
            child: Text("Fixed Column")
        )
        
        let constrainedColumn = Box(
            height: .points(25),
            flexGrow: 2,
            flexShrink: 1,
            minWidth: .points(15),
            maxWidth: .points(35),
            child: Text("Constrained Column")
        )
        
        let constrainedLayout = Box(
            flexDirection: .row,
            width: .points(120),
            height: .points(30),
            children: [flexibleColumn, fixedColumn, constrainedColumn]
        )
        
        let containerRect = FlexLayout.Rect(x: 0, y: 0, width: 120, height: 30)
        
        // Act
        let layout = constrainedLayout.calculateLayout(in: containerRect)
        
        // Assert & Document
        print("\n=== Constrained Layout Snapshot ===")
        print("Container: 120x30")
        print("Flexible (grow:1, min:20, max:40): \(layout.childRects[0])")
        print("Fixed (30px, no flex): \(layout.childRects[1])")
        print("Constrained (grow:2, min:15, max:35): \(layout.childRects[2])")
        
        let flexRect = layout.childRects[0]
        let fixedRect = layout.childRects[1]
        let constrainedRect = layout.childRects[2]
        
        // Verify constraints
        #expect(flexRect.width >= 20 && flexRect.width <= 40, "Flexible column should respect min/max")
        #expect(fixedRect.width == 30, "Fixed column should maintain width")
        #expect(constrainedRect.width >= 15 && constrainedRect.width <= 35, "Constrained column should respect min/max")
        
        // Verify total layout
        let totalWidth = flexRect.width + fixedRect.width + constrainedRect.width
        #expect(totalWidth <= 120, "Total width should not exceed container")
    }
}
