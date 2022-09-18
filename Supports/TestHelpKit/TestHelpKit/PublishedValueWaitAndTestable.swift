//
//  PublishedValueWaitAndTestable.swift
//  TestHelpKit
//
//  Created by sudo.park on 2022/09/17.
//

import XCTest
import Combine


public protocol PublishedValueWaitAndTestable: XCTestCase {
    
    var cancellables: Set<AnyCancellable>! { get set }
}


extension PublishedValueWaitAndTestable {
    
    public func waitPublishedValues<P: Publisher>(
        _ expect: XCTestExpectation,
        _ publisher: P,
        _ timeout: TimeInterval = 0.001,
        _ action: (() -> Void)? = nil
    ) -> [P.Output] {
        
        var sender = [P.Output]()
        
        publisher
            .sink { _ in } receiveValue: {
                sender.append($0)
                expect.fulfill()
            }
            .store(in: &self.cancellables)
        
        action?()
        self.wait(for: [expect], timeout: timeout)
        
        return sender
    }
    
    public func waitFirstPublishedValue<P: Publisher>(
        _ expect: XCTestExpectation,
        _ publisher: P,
        _ timeout: TimeInterval = 0.001,
        _ action: (() -> Void)? = nil
    ) -> P.Output? {
        return self.waitPublishedValues(expect, publisher, timeout, action).first
    }
    
    public func waitPublisherFailure<P: Publisher>(
        _ expect: XCTestExpectation,
        _ publisher: P,
        _ timeout: TimeInterval = 0.001,
        _ action: (() -> Void)? = nil
    ) -> P.Failure? {
        
        var failure: P.Failure?
        
        publisher
            .sink { completion in
                if case let .failure(error) = completion {
                    failure = error
                }
                expect.fulfill()
            } receiveValue: { _ in }
            .store(in: &self.cancellables)
        
        action?()
        self.wait(for: [expect], timeout: timeout)
        
        return failure
    }
}
