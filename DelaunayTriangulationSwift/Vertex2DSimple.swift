//
//  Vertex2DSimple.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//
import UIKit

public struct Vertex2DSimple {
    
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    public let x: CGFloat
    public let y: CGFloat
}

extension Vertex2DSimple: Equatable { }

public func ==(lhs: Vertex2DSimple, rhs: Vertex2DSimple) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}

extension Vertex2DSimple: Hashable {
    public var hashValue: Int {
        return "\(x)\(y)".hashValue
    }
}
