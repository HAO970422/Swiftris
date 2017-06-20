//
//  Swiftris.swift
//  Swiftris
//
//  Created by HaoZ on 17/5/10.
//  Copyright © 2017年 张昊. All rights reserved.
//

//the total number of rows and columns on the game board
let NumColumns = 10
let NumRows = 20

//block initial position
let StartingColumn = 4
let StartingRow = 0

let PreviewColumn = 12
let PreviewRow = 1

let PointsPerLine = 10
let LevelThreshold = 500

protocol SwiftrisDelegate
{
    //Invoked when the current round of Swiftris ends
    func gameDidEnd(swiftris: Swiftris)
    
    //Invoked after a new game has begun
    func gameDidBegin(swiftris: Swiftris)
    
    //Invoked when the falling shape has become part of the game board
    func gameShapeDidLand(swiftris: Swiftris)
    
    //Invoked when the falling shape has changed its location
    func gameShapeDidMove(swiftris: Swiftris)
    
    //Invoked when the falling shape has changed its location after being dropped
    func gameShapeDidDrop(swiftris: Swiftris)
    
    //Invoked when the game has reached a new level
    func gameDidLevelUp(swiftris: Swiftris)
}

class Swiftris
{
    var blockArray: Array2D<Block> //game scene
    var nextShape: Shape?
    var fallingShape: Shape?
    
    var delegate: SwiftrisDelegate?
    
    //Score represents their cumulative point total
    var score = 0
    //Level represents which level of Swiftris they're playing on
    var level = 1
    
    var lines = 0
    
    init()
    {
        fallingShape = nil
        nextShape = nil
        blockArray = Array2D<Block>(columns: NumColumns, rows: NumRows)
    }
    
    func beginGame()
    {
        if(nextShape == nil)
        {
            nextShape = Shape.random(startingColumn: PreviewColumn, startingRow: PreviewRow)
        }
        
        delegate?.gameDidBegin(swiftris: self)
    }
    
    func newShape() -> (fallingShape: Shape?, nextShape: Shape?)
    {
        fallingShape = nextShape
        nextShape = Shape.random(startingColumn: PreviewColumn, startingRow: PreviewRow)
        fallingShape?.moveTo(column: StartingColumn, row: StartingRow)
        
        guard detectIllegalPlacement() == false else
        {
            nextShape = fallingShape
            nextShape!.moveTo(column: PreviewColumn, row: PreviewRow)
            endGame()
            return (nil, nil)
        }
        
        return (fallingShape, nextShape)
    }
    
    // check both block boundary conditions
    func detectIllegalPlacement() -> Bool
    {
        guard let shape = fallingShape else
        {
            return false
        }
        for block in shape.blocks
        {
            //whether a block exceeds the legal size of the game board
            if block.column < 0 || block.column >= NumColumns || block.row < 0 || block.row >= NumRows
            {
                return true
            }
            //whether a block's current location overlaps with an existing block
            else if blockArray[block.column, block.row] != nil
            {
                return true
            }
        }
        return false
    }
    //adds the falling shape to the collection of blocks maintained by Swiftris
    func settleShape()
    {
        guard let shape = fallingShape else {
            return
        }
        
        for block in shape.blocks
        {
            blockArray[block.column, block.row] = block
        }
        
        fallingShape = nil
        
        delegate?.gameShapeDidLand(swiftris: self)
    }
    
    func detectTouch() -> Bool
    {
        guard let shape = fallingShape else {
            return false
        }
        
        for bottomBlock in shape.bottomBlocks
        {
            if bottomBlock.row == NumRows-1 || blockArray[bottomBlock.column, bottomBlock.row+1] != nil
            {
                return true
            }
        }
        return false
    }
    
    func endGame()
    {
        delegate?.gameDidEnd(swiftris: self)
        
        lines = 0
        score = 0
        level = 1
    }
    
    //drop the shape by a single row until it detects an illegal placement state
    func dropShape()
    {
        guard let shape = fallingShape else {
            return
        }
        
        while detectIllegalPlacement() == false
        {
            shape.lowerShapeByOneRow()
        }
        
        shape.raiseShapeByOneRow()
        delegate?.gameShapeDidDrop(swiftris: self)
    }
    
    //call once every tick
    func letShapeFall()
    {
        guard let shape = fallingShape else {
            return
        }
        
        shape.lowerShapeByOneRow()
        
        if detectIllegalPlacement()
        {
            shape.raiseShapeByOneRow()
            if detectIllegalPlacement()
            {
                endGame()
            }
            else
            {
                settleShape()
            }
        }
        else
        {
            delegate?.gameShapeDidMove(swiftris: self)
            if detectTouch()
            {
                settleShape()
            }
        }
    }
    
    func rotateShape()
    {
        guard let shape = fallingShape else {
            return
        }
        
        shape.rotateClockwise()
        
        guard detectIllegalPlacement() == false else {
            shape.rotateCounterClockwise()
            return
        }
        delegate?.gameShapeDidMove(swiftris: self)
    }
    
    func moveShapeLeft()
    {
        guard let shape = fallingShape else {
            return
        }
        
        shape.shiftLeftByOneColumn()
        
        guard detectIllegalPlacement() == false else {
            shape.shiftRightByOneColumn()
            return
        }
        
        delegate?.gameShapeDidMove(swiftris: self)
    }
    
    func moveShapeRight()
    {
        guard let shape = fallingShape else {
            return
        }
        
        shape.shiftRightByOneColumn()
        
        guard detectIllegalPlacement() == false else {
            shape.shiftLeftByOneColumn()
            return
        }
        
        delegate?.gameShapeDidMove(swiftris: self)
    }
    
    
    func removeCompletedLines() -> (linesRemoved: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>)
    {
        var removedLines = Array<Array<Block>>()
        for row in (1..<NumRows).reversed()
        {
            var rowOfBlocks = Array<Block>()
            
            for column in 0..<NumColumns
            {
                guard let block = blockArray[column, row] else {
                    continue
                }
                
                rowOfBlocks.append(block)
            }
            
            if rowOfBlocks.count == NumColumns
            {
                removedLines.append(rowOfBlocks)
                
                for block in rowOfBlocks
                {
                    blockArray[block.column, block.row] = nil
                }
            }
        }
        // check if we recovered any lines at all, if not, we return empty arrays
        if removedLines.count == 0
        {
            return ([], [])
        }
        
        let pointsEarned = removedLines.count * PointsPerLine * level
        score += pointsEarned
        lines += removedLines.count
        //points exceed their level times 1000, level up and inform delegate
        if score >= level * LevelThreshold
        {
            level += 1
            delegate?.gameDidLevelUp(swiftris: self)
        }
        
        var fallenBlocks = Array<Array<Block>>()
        for column in 0..<NumColumns {
            var fallenBlocksArray = Array<Block>()
            
            for row in (1..<removedLines[0][0].row).reversed()
            {
                guard let block = blockArray[column, row] else {
                    continue
                }
                
                var newRow = row
                
                while (newRow < NumRows-1 && blockArray[column, newRow+1] == nil) {
                    newRow += 1
                }
                
                block.row = newRow
                
                blockArray[column, row] = nil
                blockArray[column, newRow] = block
                
                fallenBlocksArray.append(block)
            }
            
            if fallenBlocksArray.count > 0
            {
                fallenBlocks.append(fallenBlocksArray)
            }
        }
        
        return (removedLines, fallenBlocks)
    }
    
    func removeAllBlocks() -> Array<Array<Block>>
    {
        var allBlocks = Array<Array<Block>>()
        
        for row in 0..<NumRows
        {
            var rowOfBlocks = Array<Block>()
            for column in 0..<NumColumns
            {
                guard let block = blockArray[column, row] else {
                    continue
                }
                
                rowOfBlocks.append(block)
                blockArray[column, row] = nil
            }
            
            allBlocks.append(rowOfBlocks)
        }
        
        return allBlocks
    }

}




