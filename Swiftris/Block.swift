//
//  Block.swift
//  Swiftris
//
//  Created by HaoZ on 17/5/10.
//  Copyright © 2017年 张昊. All rights reserved.
//

import SpriteKit

let NumberOfColors: UInt32 = 6

//implement CustomStringConvertible protocol
enum BlockColor: Int, CustomStringConvertible {
    case Blue = 0, Orange, Purple, Red, Teal, Yellow
    
    var spriteName: String
    {
        switch self
        {
        case .Blue:
            return "blue"
        case .Orange:
            return "orange"
        case .Purple:
            return "purple"
        case .Red:
            return "red"
        case .Teal:
            return "teal"
        case .Yellow:
            return "yellow"
        }
    }
    
    //returns the spriteName of the color to describe the object， protocol
    var description: String
    {
        return self.spriteName
    }
    
    static func random() -> BlockColor
    {
        return BlockColor(rawValue:Int(arc4random_uniform(NumberOfColors)))!
    }

}

//hashable allows us to store block in Array2D
class Block: Hashable, CustomStringConvertible
{
    //Constants
    let color : BlockColor
    
    //Properties
    var column: Int
    var row: Int
    // visual element of the block
    var sprite: SKSpriteNode?
    
    var spriteName: String
    {
        return color.spriteName
    }
    
    var hashValue: Int
    {
        return self.column ^ self.row
    }
    
    var description: String
    {
        return "\(color): [\(column), \(row)]"
    }
    
    init(column: Int, row: Int, color:BlockColor)
    {
        self.column = column
        self.row = row
        self.color = color
    }
}

//hashable protocol requires
func ==(lhs: Block, rhs: Block) -> Bool
{
    return lhs.column == rhs.column && lhs.row == rhs.row && lhs.color.rawValue == rhs.color.rawValue
}











