import XCTest
@testable import SpeedyLauncher

@MainActor
final class StorageServiceTests: XCTestCase {

    var storageService: StorageService!

    override func setUp() async throws {
        try await super.setUp()
        storageService = StorageService.shared
        // Reset to empty state for each test
        storageService.settings = AppSettings(items: [])
    }

    override func tearDown() async throws {
        // Clean up after tests
        storageService.settings = AppSettings(items: [])
        try await super.tearDown()
    }

    // MARK: - Add Item Tests

    func testAddItem() {
        let item = ActionItem(name: "Test App", type: .app, path: "/path/to/app")

        storageService.addItem(item)

        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items.first?.name, "Test App")
        XCTAssertEqual(storageService.settings.items.first?.id, item.id)
    }

    func testAddMultipleItems() {
        let item1 = ActionItem(name: "App 1", type: .app)
        let item2 = ActionItem(name: "App 2", type: .folder)
        let item3 = ActionItem(name: "App 3", type: .shortcut)

        storageService.addItem(item1)
        storageService.addItem(item2)
        storageService.addItem(item3)

        XCTAssertEqual(storageService.settings.items.count, 3)
        XCTAssertEqual(storageService.settings.items[0].name, "App 1")
        XCTAssertEqual(storageService.settings.items[1].name, "App 2")
        XCTAssertEqual(storageService.settings.items[2].name, "App 3")
    }

    func testAddItemToCategory() {
        let category = ActionItem(name: "My Category", type: .category)
        storageService.addItem(category)

        let childItem = ActionItem(name: "Child App", type: .app, path: "/path")
        storageService.addItem(childItem, toCategory: category.id)

        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items[0].children?.count, 1)
        XCTAssertEqual(storageService.settings.items[0].children?.first?.name, "Child App")
    }

    func testAddItemToNonExistentCategory() {
        let childItem = ActionItem(name: "Orphan", type: .app)
        let fakeID = UUID()

        storageService.addItem(childItem, toCategory: fakeID)

        // Item should not be added since category doesn't exist
        XCTAssertEqual(storageService.settings.items.count, 0)
    }

    // MARK: - Update Item Tests

    func testUpdateTopLevelItem() {
        var item = ActionItem(name: "Original", type: .app, path: "/original")
        storageService.addItem(item)

        item.name = "Updated"
        item.path = "/updated"
        storageService.updateItem(item)

        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items.first?.name, "Updated")
        XCTAssertEqual(storageService.settings.items.first?.path, "/updated")
    }

    func testUpdateItemInCategory() {
        let category = ActionItem(name: "Category", type: .category)
        storageService.addItem(category)

        var childItem = ActionItem(name: "Child", type: .app)
        storageService.addItem(childItem, toCategory: category.id)

        childItem.name = "Updated Child"
        storageService.updateItem(childItem)

        XCTAssertEqual(storageService.settings.items[0].children?.first?.name, "Updated Child")
    }

    func testUpdateNonExistentItem() {
        let item = ActionItem(name: "Ghost", type: .app)

        // This should not crash
        storageService.updateItem(item)

        XCTAssertTrue(storageService.settings.items.isEmpty)
    }

    // MARK: - Delete Item Tests

    func testDeleteTopLevelItem() {
        let item = ActionItem(name: "ToDelete", type: .app)
        storageService.addItem(item)

        XCTAssertEqual(storageService.settings.items.count, 1)

        storageService.deleteItem(item)

        XCTAssertTrue(storageService.settings.items.isEmpty)
    }

    func testDeleteItemFromCategory() {
        let category = ActionItem(name: "Category", type: .category)
        storageService.addItem(category)

        let child = ActionItem(name: "Child", type: .app)
        storageService.addItem(child, toCategory: category.id)

        XCTAssertEqual(storageService.settings.items[0].children?.count, 1)

        storageService.deleteItem(child)

        XCTAssertEqual(storageService.settings.items[0].children?.count, 0)
    }

    func testDeleteCategoryAlsoRemovesChildren() {
        var category = ActionItem(name: "Category", type: .category)
        let child = ActionItem(name: "Child", type: .app)
        category = ActionItem(
            id: category.id,
            name: category.name,
            type: category.type,
            children: [child]
        )
        storageService.addItem(category)

        storageService.deleteItem(category)

        XCTAssertTrue(storageService.settings.items.isEmpty)
    }

    // MARK: - Move Item Tests

    func testMoveItemUsingIndexSet() {
        let item1 = ActionItem(name: "Item 1", type: .app)
        let item2 = ActionItem(name: "Item 2", type: .app)
        let item3 = ActionItem(name: "Item 3", type: .app)

        storageService.addItem(item1)
        storageService.addItem(item2)
        storageService.addItem(item3)

        // Move item at index 0 to index 3 (end)
        storageService.moveItem(from: IndexSet(integer: 0), to: 3)

        XCTAssertEqual(storageService.settings.items[0].name, "Item 2")
        XCTAssertEqual(storageService.settings.items[1].name, "Item 3")
        XCTAssertEqual(storageService.settings.items[2].name, "Item 1")
    }

    func testReorderItemToLowerIndex() {
        let item1 = ActionItem(name: "Item 1", type: .app)
        let item2 = ActionItem(name: "Item 2", type: .app)
        let item3 = ActionItem(name: "Item 3", type: .app)

        storageService.addItem(item1)
        storageService.addItem(item2)
        storageService.addItem(item3)

        // Move item3 to index 0
        storageService.reorderItem(item3.id, toIndex: 0)

        XCTAssertEqual(storageService.settings.items[0].name, "Item 3")
        XCTAssertEqual(storageService.settings.items[1].name, "Item 1")
        XCTAssertEqual(storageService.settings.items[2].name, "Item 2")
    }

    func testReorderItemToHigherIndex() {
        let item1 = ActionItem(name: "Item 1", type: .app)
        let item2 = ActionItem(name: "Item 2", type: .app)
        let item3 = ActionItem(name: "Item 3", type: .app)

        storageService.addItem(item1)
        storageService.addItem(item2)
        storageService.addItem(item3)

        // Move item1 to index 3
        storageService.reorderItem(item1.id, toIndex: 3)

        XCTAssertEqual(storageService.settings.items[0].name, "Item 2")
        XCTAssertEqual(storageService.settings.items[1].name, "Item 3")
        XCTAssertEqual(storageService.settings.items[2].name, "Item 1")
    }

    func testReorderNonExistentItem() {
        let item = ActionItem(name: "Item", type: .app)
        storageService.addItem(item)

        let fakeID = UUID()
        storageService.reorderItem(fakeID, toIndex: 0)

        // Should not crash and item should remain in place
        XCTAssertEqual(storageService.settings.items.count, 1)
    }

    // MARK: - Move Item In Category Tests

    func testMoveItemInCategory() {
        var category = ActionItem(name: "Category", type: .category)
        let child1 = ActionItem(name: "Child 1", type: .app)
        let child2 = ActionItem(name: "Child 2", type: .app)
        let child3 = ActionItem(name: "Child 3", type: .app)

        category = ActionItem(
            id: category.id,
            name: category.name,
            type: .category,
            children: [child1, child2, child3]
        )
        storageService.addItem(category)

        storageService.moveItemInCategory(category.id, from: IndexSet(integer: 0), to: 3)

        let children = storageService.settings.items[0].children
        XCTAssertEqual(children?[0].name, "Child 2")
        XCTAssertEqual(children?[1].name, "Child 3")
        XCTAssertEqual(children?[2].name, "Child 1")
    }

    func testReorderItemInCategory() {
        var category = ActionItem(name: "Category", type: .category)
        let child1 = ActionItem(name: "Child 1", type: .app)
        let child2 = ActionItem(name: "Child 2", type: .app)
        let child3 = ActionItem(name: "Child 3", type: .app)

        category = ActionItem(
            id: category.id,
            name: category.name,
            type: .category,
            children: [child1, child2, child3]
        )
        storageService.addItem(category)

        // Move child1 to position of child3
        storageService.reorderItemInCategory(category.id, itemID: child1.id, targetItemID: child3.id)

        let children = storageService.settings.items[0].children
        XCTAssertEqual(children?[0].name, "Child 2")
        XCTAssertEqual(children?[1].name, "Child 3")
        XCTAssertEqual(children?[2].name, "Child 1")
    }

    // MARK: - Move Item To/From Category Tests

    func testMoveItemToCategory() {
        let item = ActionItem(name: "Item", type: .app)
        let category = ActionItem(name: "Category", type: .category)

        storageService.addItem(item)
        storageService.addItem(category)

        XCTAssertEqual(storageService.settings.items.count, 2)

        storageService.moveItemToCategory(item.id, categoryID: category.id)

        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items[0].name, "Category")
        XCTAssertEqual(storageService.settings.items[0].children?.count, 1)
        XCTAssertEqual(storageService.settings.items[0].children?.first?.name, "Item")
    }

    func testMoveItemOutOfCategory() {
        var category = ActionItem(name: "Category", type: .category)
        let child = ActionItem(name: "Child", type: .app)
        category = ActionItem(
            id: category.id,
            name: category.name,
            type: .category,
            children: [child]
        )

        storageService.addItem(category)

        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items[0].children?.count, 1)

        storageService.moveItemOutOfCategory(child.id, fromCategoryID: category.id, toIndex: 0)

        XCTAssertEqual(storageService.settings.items.count, 2)
        XCTAssertEqual(storageService.settings.items[0].name, "Child")
        XCTAssertEqual(storageService.settings.items[1].children?.count, 0)
    }

    // MARK: - Drag and Drop (moveItem to DropTarget) Tests

    private func makeThreeTopLevelItems() -> [ActionItem] {
        let items = [
            ActionItem(name: "One", type: .app),
            ActionItem(name: "Two", type: .app),
            ActionItem(name: "Three", type: .app)
        ]
        storageService.settings.items = items
        return items
    }

    func testDropMovesTopLevelItemDown() {
        let items = makeThreeTopLevelItems()

        // Drop "One" at the end of the list
        storageService.moveItem(items[0].id, to: .topLevel(index: 3))

        XCTAssertEqual(storageService.settings.items.map(\.name), ["Two", "Three", "One"])
    }

    func testDropMovesTopLevelItemUp() {
        let items = makeThreeTopLevelItems()

        // Drop "Three" before "One"
        storageService.moveItem(items[2].id, to: .topLevel(index: 0))

        XCTAssertEqual(storageService.settings.items.map(\.name), ["Three", "One", "Two"])
    }

    func testDropOnSelfIsNoOp() {
        let items = makeThreeTopLevelItems()

        // Dropping just before and just after itself both change nothing
        storageService.moveItem(items[1].id, to: .topLevel(index: 1))
        XCTAssertEqual(storageService.settings.items.map(\.name), ["One", "Two", "Three"])

        storageService.moveItem(items[1].id, to: .topLevel(index: 2))
        XCTAssertEqual(storageService.settings.items.map(\.name), ["One", "Two", "Three"])
    }

    func testDropTopLevelItemIntoCategory() {
        let item = ActionItem(name: "Loose", type: .app)
        let category = ActionItem(name: "Box", type: .category, children: [])
        storageService.settings.items = [item, category]

        storageService.moveItem(item.id, to: .intoCategory(id: category.id))

        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items[0].children?.map(\.name), ["Loose"])
    }

    func testDropChildOutOfCategoryToTopLevel() {
        let child = ActionItem(name: "Child", type: .app)
        let category = ActionItem(name: "Box", type: .category, children: [child])
        let other = ActionItem(name: "Other", type: .app)
        storageService.settings.items = [category, other]

        storageService.moveItem(child.id, to: .topLevel(index: 0))

        XCTAssertEqual(storageService.settings.items.map(\.name), ["Child", "Box", "Other"])
        XCTAssertEqual(storageService.settings.items[1].children?.count, 0)
    }

    func testDropReordersWithinCategory() {
        let a = ActionItem(name: "A", type: .app)
        let b = ActionItem(name: "B", type: .app)
        let c = ActionItem(name: "C", type: .app)
        let category = ActionItem(name: "Box", type: .category, children: [a, b, c])
        storageService.settings.items = [category]

        // Move "C" to the front of the category
        storageService.moveItem(c.id, to: .inCategory(id: category.id, index: 0))

        XCTAssertEqual(storageService.settings.items[0].children?.map(\.name), ["C", "A", "B"])
    }

    func testDropMovesItemBetweenCategories() {
        let child = ActionItem(name: "Mover", type: .app)
        let source = ActionItem(name: "Source", type: .category, children: [child])
        let destination = ActionItem(name: "Destination", type: .category, children: [])
        storageService.settings.items = [source, destination]

        storageService.moveItem(child.id, to: .inCategory(id: destination.id, index: 0))

        XCTAssertEqual(storageService.settings.items[0].children?.count, 0)
        XCTAssertEqual(storageService.settings.items[1].children?.map(\.name), ["Mover"])
    }

    func testCategoryCannotBeDroppedIntoAnotherCategory() {
        let inner = ActionItem(name: "Inner", type: .category, children: [])
        let outer = ActionItem(name: "Outer", type: .category, children: [])
        storageService.settings.items = [inner, outer]

        storageService.moveItem(inner.id, to: .intoCategory(id: outer.id))

        // Both stay at the top level; nesting is not supported
        XCTAssertEqual(storageService.settings.items.map(\.name), ["Inner", "Outer"])
        XCTAssertEqual(storageService.settings.items[1].children?.count, 0)
    }

    func testCategoryDroppedOnCategoryReordersInstead() {
        let first = ActionItem(name: "First", type: .category, children: [])
        let second = ActionItem(name: "Second", type: .category, children: [])
        storageService.settings.items = [first, second]

        // Dragging "Second" onto "First" can't nest, so it takes First's slot
        storageService.moveItem(second.id, to: .intoCategory(id: first.id))

        XCTAssertEqual(storageService.settings.items.map(\.name), ["Second", "First"])
        XCTAssertEqual(storageService.settings.items[0].children?.count, 0)
        XCTAssertEqual(storageService.settings.items[1].children?.count, 0)
    }

    func testCategoryDroppedOnChildRowReordersToThatCategoryPosition() {
        let child = ActionItem(name: "Child", type: .app)
        let box = ActionItem(name: "Box", type: .category, children: [child])
        let mover = ActionItem(name: "Mover", type: .category, children: [])
        storageService.settings.items = [box, mover]

        // Dropping a category onto a child row lands it at the category's slot
        storageService.moveItem(mover.id, to: .inCategory(id: box.id, index: 0))

        XCTAssertEqual(storageService.settings.items.map(\.name), ["Mover", "Box"])
        // The child must stay put
        XCTAssertEqual(storageService.settings.items[1].children?.map(\.name), ["Child"])
    }

    func testCategoriesRemainReorderableAtTopLevel() {
        let category = ActionItem(name: "Box", type: .category, children: [])
        let item = ActionItem(name: "Item", type: .app)
        storageService.settings.items = [category, item]

        storageService.moveItem(category.id, to: .topLevel(index: 2))

        XCTAssertEqual(storageService.settings.items.map(\.name), ["Item", "Box"])
    }

    func testDropWithUnknownItemIDIsNoOp() {
        _ = makeThreeTopLevelItems()

        storageService.moveItem(UUID(), to: .topLevel(index: 0))

        XCTAssertEqual(storageService.settings.items.map(\.name), ["One", "Two", "Three"])
    }

    func testDropIntoNonExistentCategoryIsNoOp() {
        let items = makeThreeTopLevelItems()

        storageService.moveItem(items[0].id, to: .intoCategory(id: UUID()))

        // The item must not vanish when the destination doesn't exist
        XCTAssertEqual(storageService.settings.items.map(\.name), ["One", "Two", "Three"])
    }

    func testDropIndexBeyondEndIsClamped() {
        let items = makeThreeTopLevelItems()

        storageService.moveItem(items[0].id, to: .topLevel(index: 99))

        XCTAssertEqual(storageService.settings.items.map(\.name), ["Two", "Three", "One"])
    }

    // MARK: - Toggle Category Expanded Tests

    func testToggleCategoryExpanded() {
        let category = ActionItem(name: "Category", type: .category, isExpanded: true)
        storageService.addItem(category)

        XCTAssertTrue(storageService.settings.items[0].isExpanded)

        storageService.toggleCategoryExpanded(category)

        XCTAssertFalse(storageService.settings.items[0].isExpanded)

        storageService.toggleCategoryExpanded(storageService.settings.items[0])

        XCTAssertTrue(storageService.settings.items[0].isExpanded)
    }

    // MARK: - Find Item Tests

    func testFindTopLevelItemByID() {
        let item = ActionItem(name: "Findable", type: .app)
        storageService.addItem(item)

        let found = storageService.findItem(byID: item.id)

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Findable")
    }

    func testFindItemInCategoryByID() {
        var category = ActionItem(name: "Category", type: .category)
        let child = ActionItem(name: "Hidden Child", type: .app)
        category = ActionItem(
            id: category.id,
            name: category.name,
            type: .category,
            children: [child]
        )
        storageService.addItem(category)

        let found = storageService.findItem(byID: child.id)

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Hidden Child")
    }

    func testFindNonExistentItem() {
        let item = ActionItem(name: "Exists", type: .app)
        storageService.addItem(item)

        let found = storageService.findItem(byID: UUID())

        XCTAssertNil(found)
    }

    // MARK: - Find Parent Category Tests

    func testFindParentCategory() {
        var category = ActionItem(name: "Parent", type: .category)
        let child = ActionItem(name: "Child", type: .app)
        category = ActionItem(
            id: category.id,
            name: category.name,
            type: .category,
            children: [child]
        )
        storageService.addItem(category)

        let parent = storageService.findParentCategory(forItemID: child.id)

        XCTAssertNotNil(parent)
        XCTAssertEqual(parent?.name, "Parent")
    }

    func testFindParentCategoryForTopLevelItem() {
        let item = ActionItem(name: "Orphan", type: .app)
        storageService.addItem(item)

        let parent = storageService.findParentCategory(forItemID: item.id)

        XCTAssertNil(parent)
    }

    func testFindParentCategoryForNonExistentItem() {
        let category = ActionItem(name: "Category", type: .category)
        storageService.addItem(category)

        let parent = storageService.findParentCategory(forItemID: UUID())

        XCTAssertNil(parent)
    }

    // MARK: - Settings Property Tests

    func testSettingsItemsCount() {
        XCTAssertEqual(storageService.settings.items.count, 0)

        storageService.addItem(ActionItem(name: "1", type: .app))
        XCTAssertEqual(storageService.settings.items.count, 1)

        storageService.addItem(ActionItem(name: "2", type: .app))
        XCTAssertEqual(storageService.settings.items.count, 2)
    }

    // MARK: - Edge Cases

    func testAddItemWithKeyboardShortcut() {
        let shortcut = KeyboardShortcutConfig(key: "A", modifiers: [.command])
        let item = ActionItem(
            name: "Shortcut App",
            type: .app,
            keyboardShortcut: shortcut
        )

        storageService.addItem(item)

        let retrieved = storageService.findItem(byID: item.id)
        XCTAssertEqual(retrieved?.keyboardShortcut?.key, "A")
        XCTAssertEqual(retrieved?.keyboardShortcut?.modifiers, [.command])
    }

    func testMoveDisabledItem() {
        let item = ActionItem(name: "Disabled", type: .app, isEnabled: false)
        storageService.addItem(item)
        storageService.addItem(ActionItem(name: "Other", type: .app))

        storageService.reorderItem(item.id, toIndex: 2)

        XCTAssertEqual(storageService.settings.items[1].name, "Disabled")
        XCTAssertFalse(storageService.settings.items[1].isEnabled)
    }

    func testNestedCategoriesNotSupported() {
        // Categories should be top-level only
        let parentCategory = ActionItem(name: "Parent", type: .category)
        storageService.addItem(parentCategory)

        let nestedCategory = ActionItem(name: "Nested", type: .category)
        storageService.addItem(nestedCategory, toCategory: parentCategory.id)

        // The nested category should be added but with empty children
        // since we're adding a category as a child
        XCTAssertEqual(storageService.settings.items[0].children?.count, 1)
    }

    // MARK: - Export/Import Tests

    func testExportSettings() throws {
        let item = ActionItem(name: "ExportTest", type: .app, path: "/path/to/app")
        storageService.addItem(item)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_export_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try storageService.exportSettings(to: tempURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        // Verify exported content
        let data = try Data(contentsOf: tempURL)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        XCTAssertEqual(decoded.items.count, 1)
        XCTAssertEqual(decoded.items.first?.name, "ExportTest")
    }

    func testImportSettings() throws {
        // Create a settings file to import
        let importItem = ActionItem(name: "ImportedApp", type: .app, path: "/imported/path")
        let importSettings = AppSettings(
            items: [importItem],
            globalHotkey: KeyboardShortcutConfig(key: "I", modifiers: [.option]),
            launchAtLogin: true
        )

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let encoder = JSONEncoder()
        let data = try encoder.encode(importSettings)
        try data.write(to: tempURL)

        // Import the settings
        try storageService.importSettings(from: tempURL)

        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items.first?.name, "ImportedApp")
        XCTAssertEqual(storageService.settings.globalHotkey?.key, "I")
        XCTAssertTrue(storageService.settings.launchAtLogin)
    }

    func testImportSettingsWithCategories() throws {
        let child = ActionItem(name: "ChildApp", type: .app, path: "/child")
        let category = ActionItem(name: "ImportedCategory", type: .category, children: [child])
        let importSettings = AppSettings(items: [category])

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_cat_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let data = try JSONEncoder().encode(importSettings)
        try data.write(to: tempURL)

        try storageService.importSettings(from: tempURL)

        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items.first?.type, .category)
        XCTAssertEqual(storageService.settings.items.first?.children?.count, 1)
        XCTAssertEqual(storageService.settings.items.first?.children?.first?.name, "ChildApp")
    }

    func testImportInvalidFileThrows() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("invalid_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Write invalid JSON
        try? "{ invalid json }".data(using: .utf8)?.write(to: tempURL)

        XCTAssertThrowsError(try storageService.importSettings(from: tempURL))
    }

    func testImportNonExistentFileThrows() {
        let fakeURL = URL(fileURLWithPath: "/nonexistent/path/settings.json")
        XCTAssertThrowsError(try storageService.importSettings(from: fakeURL))
    }

    func testExportPreservesPrettyPrinting() throws {
        let item = ActionItem(name: "Pretty", type: .app)
        storageService.addItem(item)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_pretty_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try storageService.exportSettings(to: tempURL)

        let content = try String(contentsOf: tempURL, encoding: .utf8)
        // Pretty printed JSON has newlines
        XCTAssertTrue(content.contains("\n"))
    }

    // MARK: - Singleton Tests

    func testSharedInstanceIsSingleton() {
        let instance1 = StorageService.shared
        let instance2 = StorageService.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Delete Multiple Items Tests

    func testDeleteMultipleItems() {
        let item1 = ActionItem(name: "Item1", type: .app)
        let item2 = ActionItem(name: "Item2", type: .app)
        let item3 = ActionItem(name: "Item3", type: .app)

        storageService.addItem(item1)
        storageService.addItem(item2)
        storageService.addItem(item3)

        XCTAssertEqual(storageService.settings.items.count, 3)

        storageService.deleteItem(item1)
        storageService.deleteItem(item3)

        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items.first?.name, "Item2")
    }

    func testDeleteNonExistentItem() {
        let item = ActionItem(name: "Exists", type: .app)
        storageService.addItem(item)

        let ghost = ActionItem(name: "Ghost", type: .app)
        storageService.deleteItem(ghost)

        // Should not crash and original item should remain
        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertEqual(storageService.settings.items.first?.name, "Exists")
    }

    // MARK: - Move Item Edge Cases

    func testMoveItemToCategoryWithNilChildren() {
        // Category initialized without children array
        let category = ActionItem(
            name: "EmptyCategory",
            type: .category,
            children: nil
        )
        storageService.settings.items = [category]

        let item = ActionItem(name: "NewItem", type: .app)
        storageService.addItem(item)

        storageService.moveItemToCategory(item.id, categoryID: category.id)

        // Children should be initialized and contain the item
        XCTAssertEqual(storageService.settings.items.count, 1)
        XCTAssertNotNil(storageService.settings.items[0].children)
        XCTAssertEqual(storageService.settings.items[0].children?.count, 1)
    }

    func testMoveItemToNonExistentCategory() {
        let item = ActionItem(name: "Item", type: .app)
        storageService.addItem(item)

        let fakeID = UUID()
        storageService.moveItemToCategory(item.id, categoryID: fakeID)

        // Item should be removed from top level but not added anywhere
        XCTAssertEqual(storageService.settings.items.count, 0)
    }

    func testMoveItemOutOfCategoryToEndOfList() {
        let child = ActionItem(name: "Child", type: .app)
        let category = ActionItem(name: "Category", type: .category, children: [child])
        let otherItem = ActionItem(name: "Other", type: .app)

        storageService.settings.items = [category, otherItem]

        storageService.moveItemOutOfCategory(child.id, fromCategoryID: category.id, toIndex: 10)

        // Should insert at end (clamped to count)
        XCTAssertEqual(storageService.settings.items.count, 3)
        XCTAssertEqual(storageService.settings.items.last?.name, "Child")
    }

    func testMoveNonExistentItemOutOfCategory() {
        let category = ActionItem(name: "Category", type: .category, children: [])
        storageService.addItem(category)

        let fakeID = UUID()
        storageService.moveItemOutOfCategory(fakeID, fromCategoryID: category.id, toIndex: 0)

        // Should not crash
        XCTAssertEqual(storageService.settings.items.count, 1)
    }

    // MARK: - Reorder Edge Cases

    func testReorderItemInNonExistentCategory() {
        let item = ActionItem(name: "Item", type: .app)
        storageService.addItem(item)

        let fakeID = UUID()
        storageService.reorderItemInCategory(fakeID, itemID: item.id, targetItemID: item.id)

        // Should not crash
        XCTAssertEqual(storageService.settings.items.count, 1)
    }

    func testMoveItemInNonExistentCategory() {
        let item = ActionItem(name: "Item", type: .app)
        storageService.addItem(item)

        let fakeID = UUID()
        storageService.moveItemInCategory(fakeID, from: IndexSet(integer: 0), to: 1)

        // Should not crash
        XCTAssertEqual(storageService.settings.items.count, 1)
    }
}
