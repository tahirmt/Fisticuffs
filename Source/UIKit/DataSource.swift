//
//  DataSource.swift
//  SwiftMVVMBinding
//
//  Created by Darren Clark on 2015-11-17.
//  Copyright © 2015 theScore. All rights reserved.
//

import UIKit

public protocol DataSourceView: class {
    typealias CellView
    
    func reloadData()
    func indexPathsForSelections() -> [NSIndexPath]?
    func select(indexPath indexPath: NSIndexPath)
    func deselect(indexPath indexPath: NSIndexPath)
    func dequeueCell(reuseIdentifier reuseIdentifier: String, indexPath: NSIndexPath) -> CellView
}


public class DataSource<S: SubscribableType, View: DataSourceView where S.ValueType: RangeReplaceableCollectionType, S.ValueType.Generator.Element: Equatable> : NSObject {
    typealias Collection = S.ValueType
    typealias Item = Collection.Generator.Element
    
    private weak var view: View?
    
    // Underlying data
    private let subscribable: S
    private let observable: Observable<Collection>?
    
    private var suppressChangeNotifications = false
    
    private var items: [Item] = []
    
    public var selections: Observable<[Item]>?
    public var deselectOnSelection = true
    public let onSelect = Event<Item>()
    public let onDeselect = Event<Item>()
    
    public var editable: Bool { return observable != nil }
    
    public init(subscribable: S, view: View) {
        self.view = view
        self.subscribable = subscribable
        self.observable = subscribable as? Observable<Collection>
        super.init()
        subscribable.subscribeArray(SubscriptionOptions()) { [weak self] new, change in
            self?.underlyingDataChanged(new, change)
        }
    }
    
    private var reuseIdentifier: String?
    private var cellSetup: ((Item, View.CellView) -> Void)?
    
    public func useCell(reuseIdentifier reuseIdentifier: String, setup: (Item, View.CellView) -> Void) {
        self.reuseIdentifier = reuseIdentifier
        cellSetup = setup
    }
    
    public var allowsMoving = false
}

extension DataSource {
    
    func underlyingDataChanged(new: [Item], _ change: ArrayChange<Item>) {
        guard suppressChangeNotifications == false else { return }
        
        items = Array(new)
        
        view?.reloadData()
    }
    
    func syncSelections() {
        guard let view = view, selections = selections else { return }
        
        let currentSelections = Set(view.indexPathsForSelections() ?? [])
        
        let expectedSelections: Set<NSIndexPath> = {
            let expected = selections.value.map { item -> NSIndexPath? in
                items.indexOf(item).map { index in
                    NSIndexPath(forItem: index, inSection: 0)
                }
            }
            return Set(expected.flatMap { $0 })
        }()
        
        let toDeselect = currentSelections.subtract(expectedSelections)
        toDeselect.forEach(view.deselect)

        let toSelect = expectedSelections.subtract(currentSelections)
        toSelect.forEach(view.select)
    }
    
}

extension DataSource {
    public func numberOfSections() -> Int {
        return 1
    }
    
    public func numberOfItems(section section: Int) -> Int {
        return items.count
    }
    
    public func itemAtIndexPath(indexPath: NSIndexPath) -> Item {
        return items[indexPath.item]
    }
    
    public func cellAtIndexPath(indexPath: NSIndexPath) -> View.CellView {
        guard let view = view else {
            preconditionFailure("view not set")
        }
        
        guard let reuseIdentifier = reuseIdentifier, cellSetup = cellSetup else {
            preconditionFailure("Cell reuseidentifier/setup block not set")
        }
        
        let item = itemAtIndexPath(indexPath)
        let cell = view.dequeueCell(reuseIdentifier: reuseIdentifier, indexPath: indexPath)
        cellSetup(item, cell)
        return cell
    }
    
    public func didSelect(indexPath indexPath: NSIndexPath) {
        let item = itemAtIndexPath(indexPath)
        selections?.value.append(item)
        onSelect.fire(item)
        
        if deselectOnSelection {
            view?.deselect(indexPath: indexPath)
            didDeselect(indexPath: indexPath)
        }
    }
    
    public func didDeselect(indexPath indexPath: NSIndexPath) {
        let item = itemAtIndexPath(indexPath)
        if let index = selections?.value.indexOf(item) {
            selections?.value.removeAtIndex(index)
        }
        onDeselect.fire(item)
    }
}

extension DataSource {
    
    func modifyUnderlyingData(@noescape block: (data: Observable<Collection>) -> Void) {
        suppressChangeNotifications = true
        defer { suppressChangeNotifications = false }
        
        assert(editable, "Underlying data must be editable")
        guard let observable = observable else {
            assertionFailure("Must have an observable to modify")
            return
        }
        
        block(data: observable)
    }
    
    public func move(source source: NSIndexPath, destination: NSIndexPath) {
        modifyUnderlyingData { data in
            let sourceIndex = data.value.startIndex.nthSuccessor(source.item)
            let item = data.value.removeAtIndex(sourceIndex)
            
            let destIndex = data.value.startIndex.nthSuccessor(destination.item)
            data.value.insert(item, atIndex: destIndex)
        }
    }
    
    public func delete(indexPath indexPath: NSIndexPath) {
        modifyUnderlyingData { data in
            let index = data.value.startIndex.nthSuccessor(indexPath.item)
            data.value.removeAtIndex(index)
        }
    }
    
}



extension ForwardIndexType {
    func nthSuccessor(n: Int) -> Self {
        assert(n >= 0, "`n` must be positive")
        
        var index = self
        for _ in 0 ..< n {
            index = index.successor()
        }
        return index
    }
}

