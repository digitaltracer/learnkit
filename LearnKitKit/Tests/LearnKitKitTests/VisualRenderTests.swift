import SwiftUI
import XCTest
@testable import LearnKitKit

#if os(macOS)
import AppKit
#endif

@MainActor
final class VisualRenderTests: XCTestCase {

    func testAllVisualPrimitivesRenderNonEmptyImages() throws {
        let array = Visual.array(ArrayVisual(cells: [.number(1), .number(2), .number(3)],
                                             pointers: [Pointer(label: "L", index: 0)],
                                             highlights: [Highlight(index: 0, range: nil, state: .active)]))
        let grid = Visual.grid(GridVisual(rows: [[.number(1), .number(2)], [.number(3), .number(4)]],
                                          pointers: [GridPointer(label: "cur", row: 1, col: 1)],
                                          highlights: [GridHighlight(row: 0, col: 0, rows: nil, cols: nil, state: .done)]))
        let tree = Visual.tree(TreeVisual(root: TreeNode(value: .number(4),
                                                         state: .active,
                                                         pointer: "cur",
                                                         left: TreeNode(value: .number(2)),
                                                         right: TreeNode(value: .number(7)))))
        let list = Visual.list(ListVisual(nodes: [.number(1), .number(2), .number(3)],
                                          links: [[1, 0], [2, 1]],
                                          pointers: [Pointer(label: "cur", index: 1)],
                                          highlights: [Highlight(index: 1, range: nil, state: .match)]))
        let graph = Visual.graph(GraphVisual(nodes: [
            GraphNode(id: "1", value: nil, x: 0.2, y: 0.2, state: .active, pointer: "cur"),
            GraphNode(id: "2", value: nil, x: 0.8, y: 0.8, state: nil, pointer: nil)
        ], edges: [
            GraphEdge(from: "1", to: "2", directed: true, weight: .number(5), state: .compare)
        ]))
        let hashmap = Visual.hashmap(HashMapVisual(entries: [
            HashEntry(key: .number(2), value: .number(0), state: .match)
        ], probe: HashProbe(key: .number(2), found: true)))
        let intervals = Visual.intervals(IntervalsVisual(rows: [
            IntervalRow(start: 1, end: 3, label: "A", state: .active),
            IntervalRow(start: 2, end: 5, label: "B", state: .done)
        ], axisMin: 0, axisMax: 6))
        let rtree = Visual.rtree(RTreeVisual(root: RNode(value: .string("{}"),
                                                         state: .active,
                                                         pointer: "go",
                                                         children: [
                                                             RNode(value: .string("{1}"), edge: "+1", state: .done),
                                                             RNode(value: .string("{}"), edge: "-1")
                                                         ])))
        let architecture = Visual.architecture(ArchitectureVisual(nodes: [
            ArchNode(id: "client", title: "Client", kind: .client, x: 0.12, y: 0.2),
            ArchNode(id: "lb", title: "Load Balancer", kind: .lb, x: 0.5, y: 0.2),
            ArchNode(id: "svc", title: "Service", subtitle: "stateless", kind: .service, x: 0.5, y: 0.7, state: .active),
            ArchNode(id: "db", title: "Database", subtitle: "primary", kind: .database, x: 0.88, y: 0.7)
        ], connectors: [
            ArchConnector(from: "client", to: "lb", label: "HTTPS", directed: true, style: .sync, state: nil),
            ArchConnector(from: "lb", to: "svc", label: nil, directed: true, style: .sync, state: nil),
            ArchConnector(from: "svc", to: "db", label: "read", directed: true, style: .async, state: .compare)
        ], groups: [
            ArchGroup(label: "App tier", nodes: ["svc", "db"])
        ]))

        let visuals: [(String, Visual)] = [
            ("array", array),
            ("grid", grid),
            ("tree", tree),
            ("list", list),
            ("graph", graph),
            ("hashmap", hashmap),
            ("intervals", intervals),
            ("rtree", rtree),
            ("architecture", architecture)
        ]

        for (name, visual) in visuals {
            try assertRenders(visual, named: name)
        }
    }

    private func assertRenders(_ visual: Visual, named name: String) throws {
        let renderer = ImageRenderer(content:
            VisualView(visual: visual)
                .frame(width: 320, height: 240)
        )

        #if os(macOS)
        let image = try XCTUnwrap(renderer.nsImage, "\(name) renderer produced no image")
        XCTAssertGreaterThan(image.size.width, 0, "\(name) image width")
        XCTAssertGreaterThan(image.size.height, 0, "\(name) image height")
        #else
        let image = try XCTUnwrap(renderer.uiImage, "\(name) renderer produced no image")
        XCTAssertGreaterThan(image.size.width, 0, "\(name) image width")
        XCTAssertGreaterThan(image.size.height, 0, "\(name) image height")
        #endif
    }
}
