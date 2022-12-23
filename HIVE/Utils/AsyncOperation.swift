//
//  AsyncOperation.swift
//  HIVE
//
//  Created by Daniel Pratt on 9/20/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation

open class AsyncOperation: Operation {
    
    public enum State: String {
        // This is non-standard casing for Swift, but it makes generating the keyPath much simpler
        case ready, executing, finished
        
        fileprivate var keyPath: String {
            return "is" + rawValue.capitalized
        }
    }
    
    public var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    
    override open var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override open var isExecuting: Bool {
        return state == .executing
    }
    
    override open var isFinished: Bool {
        return state == .finished
    }
    
    override open var isAsynchronous: Bool {
        return true
    }
    
    override open func start() {
        if isCancelled {
            state = .finished
            return
        }
        
        state = .executing
        main()
    }
    
    open override func cancel() {
        state = .finished
    }
}
