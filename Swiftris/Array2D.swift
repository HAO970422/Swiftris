//
//  Array2D.swift
//  Swiftris
//
//  Created by HaoZ on 17/5/10.
//  Copyright © 2017年 张昊. All rights reserved.
//

class Array2D<T>
{
    let columns: Int
    let rows: Int
    
    var array: Array<T?>
    
    init(columns: Int, rows: Int)
    {
        self.columns = columns
        self.rows = rows
        array = Array<T?>(repeating: nil, count: rows * columns)
    }
    
    subscript(column: Int, row: Int) -> T?
    {
        get
        {
            return array[(row * columns) + column]
        }
        set(newValue)
        {
            array[(row * columns) + column] = newValue
        }
    }
}
