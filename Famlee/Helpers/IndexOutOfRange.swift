//
//  IndexOutOfRange.swift
//  Famlee
//
//  Created by Jules Lee on 11/10/2019.
//  Copyright © 2019 Jules Lee. All rights reserved.
//

extension Collection where Indices.Iterator.Element == Index {
    subscript (exist index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
