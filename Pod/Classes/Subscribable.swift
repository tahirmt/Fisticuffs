//
//  Subscribable.swift
//  Pods
//
//  Created by Darren Clark on 2015-11-02.
//
//

public protocol Subscribable: class {
    typealias ValueType
    
    // Must be implemented.
    @warn_unused_result(message="Returned Disposable must be used to cancel the subscription")
    func subscribeDiff(options: SubscriptionOptions, callback: (ValueType?, ValueType) -> Void) -> Disposable
    
    
    // Optionally implemented
    @warn_unused_result(message="Returned Disposable must be used to cancel the subscription")
    func subscribe(options: SubscriptionOptions, callback: ValueType -> Void) -> Disposable
}

public extension Subscribable {
    
    @warn_unused_result(message="Returned Disposable must be used to cancel the subscription")
    public func subscribe(options: SubscriptionOptions = SubscriptionOptions(), callback: ValueType -> Void) -> Disposable {
        return subscribeDiff(options) { _, newValue in
            callback(newValue)
        }
    }

}


public extension Subscribable where ValueType: CollectionType, ValueType.Generator.Element : Equatable {
    
    typealias ItemType = ValueType.Generator.Element
    
    func subscribeArray(options: SubscriptionOptions = SubscriptionOptions(), callback: ([ItemType], ArrayChange<ItemType>) -> Void) -> Disposable {
        return subscribeDiff(options) { oldValue, newValue in
            if let change = oldValue?.calculateChange(newValue) {
                callback(Array(newValue), change)
            }
            else {
                callback(Array(newValue), .Set(elements: Array(newValue)))
            }
        }
    }
    
}
