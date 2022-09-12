//
//  Combine+Extensions.swift
//  Extensions
//
//  Created by sudo.park on 2022/09/12.
//

import Foundation
import Combine


extension PassthroughSubject: @unchecked Sendable where Output: Sendable { }

extension CurrentValueSubject: @unchecked Sendable where Output: Sendable { }
