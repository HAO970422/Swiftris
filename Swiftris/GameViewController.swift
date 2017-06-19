//
//  GameViewController.swift
//  Swiftris
//
//  Created by 张昊 on 17/5/1.
//  Copyright © 2017年 张昊. All rights reserved.
//

import UIKit
import SpriteKit
//import GameplayKit

//for user input and communication between GameScene and game logic
//class GameViewController: UIViewController {
class GameViewController: UIViewController, SwiftrisDelegate, UIGestureRecognizerDelegate
{
    var scene: GameScene!
    
    var swiftris: Swiftris!
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var linesLabel: UILabel!
    //keep track of last point on the screen at which a shape movement occurred or where a pan begins
    var panPointReference: CGPoint?
    
    
    //rotate
    @IBAction func didTap(_ sender: UITapGestureRecognizer)
    {
        swiftris.rotateShape()
    }
    //translate
    @IBAction func didPan(sender: UIPanGestureRecognizer)
    {
        let currentPoint = sender.translation(in: self.view)
        
        if let originalPoint = panPointReference
        {
            //user's finger moves more than 90% of BlockSize points
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9)
            {
                //move right
                if sender.velocity(in: self.view).x > CGFloat(0)
                {
                    swiftris.moveShapeRight()
                    //update reference point
                    panPointReference = currentPoint
                }
                //move left
                else
                {
                    swiftris.moveShapeLeft()
                    //update reference point
                    panPointReference = currentPoint
                }
            }
        }
        else if sender.state == .began
        {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func UpButtonPressed(_ sender: Any) {
        swiftris.rotateShape()
    }
    
    @IBAction func DownButtonPressed(_ sender: Any) {
        swiftris.dropShape()
    }
    @IBAction func LeftButtonPressed(_ sender: Any) {
        swiftris.moveShapeLeft()
    }
    @IBAction func RightButtonPressed(_ sender: Any) {
        swiftris.moveShapeRight()
    }
    @IBAction func didSwipe(sender: UISwipeGestureRecognizer)
    {
        swiftris.dropShape()
    }
    
    //each gesture recognizer to work in tandem with the others
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        //pan gesture > swipe gesture
        if gestureRecognizer is UISwipeGestureRecognizer
        {
            if otherGestureRecognizer is UIPanGestureRecognizer
            {
                return true
            }
        }
        //tap > pan
        else if gestureRecognizer is UIPanGestureRecognizer
        {
            if otherGestureRecognizer is UITapGestureRecognizer
            {
                return true
            }
        }
        
        return false
    }
    
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //configure the view
        
        // downcast is for using methods "presentScene" of subaclass
        // before, treat it as UIView,
        let skView = view as! SKView //as! operator is a forced downcast VS as? return optional value
        skView.isMultipleTouchEnabled = false
        
        //create and configure the scene
        //init the scene and fill the screen
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        scene.tick = didTick
        swiftris = Swiftris()
       
        swiftris.delegate = self
        
        swiftris.beginGame()
        
        //present the scene
        skView.presentScene(scene)
        
        /*scene.addPreviewShapeToScene(shape: swiftris.nextShape!)
        {
            self.swiftris.nextShape?.moveTo(column: StartingColumn, row: StartingRow)
            self.scene.movePreviewShape(shape: self.swiftris.nextShape!)
            {
            let nextShapes = self.swiftris.newShape()
            self.scene.startTicking()
            self.scene.addPreviewShapeToScene(shape: nextShapes.nextShape!) {}
            }
        }*/
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func didTick()
    {
        swiftris.letShapeFall()
        //swiftris.fallingShape?.lowerShapeByOneRow()
        //scene.redrawShape(shape: swiftris.fallingShape!, completion: {})
    }
    
    func nextShape()
    {
        let newShapes = swiftris.newShape()
        
        guard let fallingShape = newShapes.fallingShape else {
            return
        }
        
        self.scene.addPreviewShapeToScene(shape: newShapes.nextShape!) {}
        self.scene.movePreviewShape(shape: fallingShape)
        {
            //shut down interaction with the view
            self.view.isUserInteractionEnabled = true
            self.scene.startTicking()
        }
    }
    
    func gameDidBegin(swiftris: Swiftris) {
        
        //when the game begins, reset score and level label
        levelLabel.text = "\(swiftris.level)"
        scoreLabel.text = "\(swiftris.score)"
        linesLabel.text = "\(swiftris.lines)"
        //begin with tickLengthLevelOne
        scene.tickLengthMills = TickLengthLevelOne
        
        // The following is false when restarting a new game
        if swiftris.nextShape != nil && swiftris.nextShape!.blocks[0].sprite == nil
        {
            scene.addPreviewShapeToScene(shape: swiftris.nextShape!)
            {
                self.nextShape()
            }
        }
        else
        {
            nextShape()
        }
    }
    
    func gameDidEnd(swiftris: Swiftris) {
        view.isUserInteractionEnabled = false
        
        scene.stopTicking()
        
        //play game over sound
        scene.playSound(sound: "Sounds/gameover.mp3")
        //remove all blocks
        scene.animateCollapsingLines(linesToRemove: swiftris.removeAllBlocks(), fallenBlocks: swiftris.removeAllBlocks())
        {
            swiftris.beginGame()
        }
    }
    
    @IBAction func gameDidLevelUp(_ sender: UIButton) {
        swiftris.level = swiftris.level + 1
        levelLabel.text = "\(swiftris.level)"
        //decrease tick interval and go faster
        if scene.tickLengthMills >= 100
        {
            scene.tickLengthMills -= 100
        }
        else if scene.tickLengthMills > 50
        {
            scene.tickLengthMills -= 50
        }
        scene.playSound(sound: "Sounds/levelUp.mp3")
    }
    
    func gameDidLevelUp(swiftris: Swiftris) {
        levelLabel.text = "\(swiftris.level)"
        //decrease tick interval and go faster
        if scene.tickLengthMills >= 100
        {
            scene.tickLengthMills -= 100
        }
        else if scene.tickLengthMills > 50
        {
            scene.tickLengthMills -= 50
        }
        scene.playSound(sound: "Sounds/levelUp.mp3")
        
    }
    
    func gameShapeDidDrop(swiftris: Swiftris) {
        //stop the ticks
        scene.stopTicking()
        //redraw the shape at new location and then let it drop
        scene.redrawShape(shape: swiftris.fallingShape!)
        {
            swiftris.letShapeFall()
        }
        
        scene.playSound(sound: "Sounds/drop.mp3")
    }
    
    //check for completed lines
    func gameShapeDidLand(swiftris: Swiftris) {
        scene.stopTicking()
        
        //nextShape()
        self.view.isUserInteractionEnabled = false
        
        let removedLines = swiftris.removeCompletedLines()
        if removedLines.linesRemoved.count > 0
        {
            //update the score
            self.scoreLabel.text = "\(swiftris.score)"
            
            //update the lines
            self.linesLabel.text = "\(swiftris.lines)"
            
            //animate blocks with explosive new animation function
            scene.animateCollapsingLines(linesToRemove: removedLines.linesRemoved, fallenBlocks: removedLines.fallenBlocks)
            {
                //recursivly detect any new lines
                self.gameShapeDidLand(swiftris: swiftris)
            }
            scene.playSound(sound: "Sounds/bomb.mp3")
        }
        else
        //find none, bring in the next shape
        {
            nextShape()
        }
    }
    
    //after a shape has moved is to redraw
    func gameShapeDidMove(swiftris: Swiftris) {
        scene.redrawShape(shape: swiftris.fallingShape!) {}
    }
}



