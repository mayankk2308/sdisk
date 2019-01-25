//
//  SuperMap.swift
//  SDisk
//
//  Created by Mayank Kumar on 1/25/19.
//  Adopted from: https://stackoverflow.com/a/47081889
//  Copyright © 2019 Mayank Kumar. All rights reserved.
//

import Foundation

/// Describes a dual <-> mapping structure.
struct SuperMap<K: Hashable, V: Hashable> {
    
    private var _forward: [K : V]? = nil
    private var _backward: [V : K]? = nil
    
    var forward: [K : V] {
        mutating get  {
            _forward = _forward ?? [K : V](uniqueKeysWithValues: _backward?.lazy.map { ($1, $0) } ?? [])
            return _forward!
        }
        set {
            _forward = newValue
            _backward = nil
        }
    }
    
    var backward: [V : K] {
        mutating get {
            _backward = _backward ?? [ V : K](uniqueKeysWithValues: _forward?.lazy.map { ($1, $0) } ?? [])
            return _backward!
        }
        set {
            _backward = newValue
            _forward = nil
        }
    }
    
    init(_ dict: [K : V] = [:]) {
        forward = dict
    }
    
    init(_ values: [(K, V)]) {
        forward = [K : V](uniqueKeysWithValues: values)
    }
    
    subscript(_ key: V) -> K? {
        mutating get { return backward[key] }
        set { backward[key] = newValue }
    }
    
    subscript(_ key: K) -> V? {
        mutating get { return forward[key] }
        set { forward[key] = newValue }
    }    
}
