//
//  PublishedValueWaitAndTestable+Tests.swift
//  TestHelpKitTests
//
//  Created by sudo.park on 2022/09/17.
//

import XCTest
import Combine

import TestHelpKit


class PublishedValueWaitAndTestable_Tests: BaseTestCase, PublishedValueWaitAndTestable {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        self.cancellables = .init()
    }
    
    override func tearDownWithError() throws {
        self.cancellables.forEach { $0.cancel() }
        self.cancellables = nil
    }
}

extension PublishedValueWaitAndTestable_Tests {
    
    // 원하는 사이즈만큼 값 나오는지 확인
    func testWaitPublishedValues() async {
        // given
        let provider = PublisherProvider()
        
        // when
        let values = try? await self.waitPublishedValues(4, provider.publishValue(size: 4), self.timeout * 2) {
            try? await provider.asyncWork()
        }
        
        // then
        XCTAssertEqual(values, [0, 1, 2, 3])
    }
    
    // 원하는 사이즈보다 모자름 -> 실패
    func testWaitPublishedValues_whenPublishedElementIsNotEnough() async {
        // given
        let provider = PublisherProvider()
        
        // when
        let values = try? await self.waitPublishedValues(4, provider.publishValue(size: 3), self.timeout * 2) {
            try? await provider.asyncWork()
        }
        
        // then
        XCTAssertEqual(values, [0, 1, 2])
    }
    
    // 원하는 값 안나옴
    func testWaitPublishedValues_whenValueNotPublished_timeoutError() async {
        // given
        let provider = PublisherProvider()
        
        // when
        let values = try? await self.waitPublishedValues(4, provider.publisherNotValue(), self.timeout * 2) {
            try? await provider.asyncWork()
        }
        
        // then
        XCTAssertEqual(values, [])
    }
    
    func testWaitPublisherFailure() async {
        // given
        let provider = PublisherProvider()
        
        // when
        let error = await self.waitPublisherFailure(provider.publishError(), self.timeout * 2) {
            try? await provider.asyncWork()
        }
        
        // then
        XCTAssertNotNil(error)
    }
    
    // 최초 값 기다림 + 검증
    func testWaitFirstPublishedValue() async {
        // given
        let provider = PublisherProvider()
        
        // when
        let value = try? await self.waitFirstPublishedValue(provider.publishValue(size: 1), self.timeout * 2) {
            try? await provider.asyncWork()
        }
        
        // then
        XCTAssertEqual(value, 0)
    }
    
    // 최초 값 안나옴
    func testWaitFirstPublishedValue_timeout() async {
        // given
        let provider = PublisherProvider()
        
        // when
        let value = try? await self.waitFirstPublishedValue(provider.publisherNotValue(), self.timeout * 2)
        
        // then
        XCTAssertEqual(value, nil)
    }
}


private extension PublishedValueWaitAndTestable_Tests {
    
    class PublisherProvider {
        private let subject = PassthroughSubject<Int, Error>()
        
        func asyncWork(timeMS: UInt64 = 1) async throws {
            try await Task.sleep(nanoseconds: timeMS * 1_000_000)
        }
        
        func publishValue(size: Int) -> AnyPublisher<Int, Error> {
            return (0..<size).map { $0 }
                .publisher
                .mapError { _ -> Error in DummyError() }
                .eraseToAnyPublisher()
        }
        
        func publisherNotValue() -> AnyPublisher<Int, Error> {
            return subject.eraseToAnyPublisher()
        }
        
        func publishError() -> AnyPublisher<Int, Error> {
            struct DummyError: Error { }
            return Fail<Int, Error>(error: DummyError())
                .eraseToAnyPublisher()
        }
    }
}


private struct DummyError: Error{ }
