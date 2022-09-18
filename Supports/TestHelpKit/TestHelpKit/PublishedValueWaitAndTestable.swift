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


// MARK: - wait using XCTestExpectation

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


// MARK: - wait using async await

public struct PublisherWaitPlain {
    public var expectedSize: Int = 1
    public var assertOvertFulfill: Bool = true
    
    public init() {}
}

public struct PublisherTimeoutError: Error { }

extension PublishedValueWaitAndTestable {
    
    public func waitPublishedValues<P: Publisher>(
        _ expectSize: Int,
        _ publisher: P,
        _ timeout: TimeInterval = 0.001,
        _ action: (@Sendable () async throws -> Void)? = nil
    ) async throws -> [P.Output] {
        
        let timeoutMs = Int(timeout * 1000)
        let prefixAndTimeouted = publisher
            .prefix(expectSize)
            .timeout(.milliseconds(timeoutMs), scheduler: DispatchQueue.main)
        
        async let values = prefixAndTimeouted.values
        try await action?()
        
        var sender: [P.Output] = []
        for try await value in await values {
            sender.append(value)
        }
        
        return sender
    }
    
    public func waitFirstPublishedValue<P: Publisher>(
        _ publisher: P,
        _ timeout: TimeInterval = 0.001,
        _ action: (@Sendable () async throws -> Void)? = nil
    ) async throws -> P.Output? {
        return try await self.waitPublishedValues(1, publisher, timeout, action).first
    }
    
    public func waitPublisherFailure<P: Publisher>(
        _ publisher: P,
        _ timeout: TimeInterval = 0.001,
        _ action: (@Sendable () async throws -> Void)? = nil
    ) async -> P.Failure? {
        let timeoutMs = Int(timeout * 1000)
        let publisherWithTimeout = publisher
            .timeout(.milliseconds(timeoutMs), scheduler: DispatchQueue.main)
        
        var failure: P.Failure?
        do {
            async let values = publisherWithTimeout.values
            try await action?()
            
            for try await _ in await values { }
        } catch {
            failure = error as? P.Failure
        }
        return failure
    }
}
