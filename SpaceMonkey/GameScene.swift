//
//  GameScene.swift
//  SpaceMonkey
//
//  Created by Main Account on 4/10/15.
//  Copyright (c) 2015 WangZhuo All rights reserved.
//


//这里要做的就是为每个sprite创建类别。ground number不是针对sprite，而是针对应用边框设定的，所以当monkey碰到屏幕边缘时会弹起，而不是落到屏幕之外！


import SpriteKit
enum BodyType: UInt32 {
    case player = 1
    case enemy = 2
    case ground = 4
}




//执行SKPhysicsContactDelegate协定，标记GameScene(游戏场景)
class GameScene: SKScene,SKPhysicsContactDelegate {
    //用SKSpriteNode 类创建一个sprite。sprite是图片的副本，可在游戏里随意移动。
    let player = SKSpriteNode(imageNamed:"player")
    
    // 1首先创建一个gameOver布尔变量，不论游戏是否结束，都进行跟踪记录。
    var gameOver = false
    // 2创建一些label node，好在Sprite Kit中设置屏幕上显示的字幕。
    let endLabel = SKLabelNode(text: "Game Over")
    let endLabel2 = SKLabelNode(text: "Tap to restart!")
    let touchToBeginLabel = SKLabelNode(text: "Touch to begin!")
    let points = SKLabelNode(text: "0")
    // 3创建integer储存分数。注意，用var来标记 integer，不是let，方便之后进行修改。
    var numPoints = 0
    // 4最后创建一些action，随后制造音效。
    let explosionSound = SKAction.playSoundFileNamed("explosion.mp3",
    waitForCompletion: true)
    let coinSound = SKAction.playSoundFileNamed("coin.wav",
        waitForCompletion: false)
    
    
    
    override func didMoveToView(view: SKView) {
        //设置精灵的位置
        player.position = CGPoint(x:frame.size.width * 0.1, y: frame.size.height * 0.5)
        //将精灵添加到画面上
        addChild(player)
        //设置背景颜色
        backgroundColor = SKColor.blackColor()
        
        //Action sequence动作队列，一秒执行一次spawnEnemy
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(spawnEnemy),
                SKAction.waitForDuration(1.0)])))
    
        
        //第一行为monkey创建了一个physics body，在物理引擎的作用下，monkey因引力和其他外力而落下”。
        //注意：physics body（物理实体）的形状是圆的，仅跟monkey的形状近似而已。无需做到精确，只要凑效就好。同时将physics body设定为不旋转。
        player.physicsBody = SKPhysicsBody(circleOfRadius:player.frame.size.width * 0.3)
        //player.physicsBody?.allowsRotation = false
    
        
        //防止player掉出去
        //首先创造一个可通过CGRectInset()扩大或缩小至多20%的矩形，即monkey的活动范围。monkey的轮廓可以稍微消失在屏幕外，但不能完全消失不见。
        //然后设定场景本身的physics body。刚刚创建的physics body是圆的，此处将它变为一个循环边，即“矩形的边缘”，不过听上去更简洁些。
        let collisionFrame = CGRectInset(frame, 0, -self.size.height * 0.2)
        physicsBody = SKPhysicsBody(edgeLoopFromRect: collisionFrame)
        
        
        //两个physics body碰撞时，物理世界就会自动调用代码中的method。
        physicsWorld.contactDelegate = self
        
        
        //这里为monkey和ground设置类别和碰撞位掩码，让两者彼此碰撞；在monkey和敌人之间设置“contact（接触点）”。
        player.physicsBody?.categoryBitMask = BodyType.ground.rawValue
        player.physicsBody?.categoryBitMask = BodyType.player.rawValue
        player.physicsBody?.contactTestBitMask = BodyType.enemy.rawValue
        player.physicsBody?.collisionBitMask = BodyType.ground.rawValue
        
        //更新标签
        setupLabels()
    }
    
    
    
    //因为之前已将场景设置为物理世界的contactDelegate，两个physics body碰撞时会自动调用这个method。
    func didBeginContact(contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch(contactMask) {
        case BodyType.player.rawValue | BodyType.enemy.rawValue:
            let secondNode = contact.bodyB.node
            secondNode?.removeFromParent()
            endGame()
            let firstNode = contact.bodyA.node
            firstNode?.removeFromParent()
        default:
            return
        }
    }
    
    
    
    
    
    //更新标签
    func setupLabels() {
        // 1将“touch to begin（点击开始）”标签放在屏幕中央，字体白色，大小50pt。
        touchToBeginLabel.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        touchToBeginLabel.fontColor = UIColor.whiteColor()
        touchToBeginLabel.fontSize = 50
        addChild(touchToBeginLabel)
        
        // 2将position label设在屏幕底端，白色，大小100。
        points.position = CGPoint(x: frame.size.width/2, y: frame.size.height * 0.1)
        points.fontColor = UIColor.whiteColor()
        points.fontSize = 100  
        addChild(points)  
    }
    
    //返回随机数0/1
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    //生成一个范围内的随机数
    //#外部参数
    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    //生成敌人
    func spawnEnemy() {
        // 2设置图片
        let enemy = SKSpriteNode(imageNamed: "DBC")
        // 3设置名字
        enemy.name = "enemy"
        // 4设置位置
        enemy.position = CGPoint(x: frame.size.width + enemy.size.width/2,
            y: frame.size.height * random(min: 0, max: 1))
        // 5加入敌人
        addChild(enemy)
        
        
        //敌人的动作，移动到x轴的某位置
        //用于控制敌人在X轴上移动的固定距离。将整个屏幕画面设置为左移（-size.width），还要设置完整尺寸的sprite (-enemy.size.width)。
        //SKAction有个规定sprite移动速度的时间参数；此处设定SKAction后，每1-2秒就改变一个随机值，加快了敌人的移动速度。
        enemy.runAction(
            SKAction.moveByX(-size.width - enemy.size.width, y: 0.0,
                duration: NSTimeInterval(random(min: 1, max: 2))))
        

        
        // 1为敌人创建physics body。physics body不一定要跟sprite的形状完全吻合，近似就好。这里用的是圆形，半径设为sprite的1/4，免得碰撞效果太猛。
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width/3)
        // 2把dynamic关掉，实现物理控制sprite。
        enemy.physicsBody?.dynamic = false
        // 3防止引力对sprite的影响。这一步不言自明，主要让敌人的sprite避免物理引力的干扰。
        enemy.physicsBody?.affectedByGravity = false
        // 4这一步是为了避免sprite在physics body碰撞时旋转。
        enemy.physicsBody?.allowsRotation = false
        // 5将类别位掩码设为之前设置过的敌人类别。
        enemy.physicsBody?.categoryBitMask = BodyType.enemy.rawValue
        // 6敌人和monkey接触时，Sprite Kit发出提醒。
        enemy.physicsBody?.contactTestBitMask = BodyType.player.rawValue
        // 7为monkey设置 collisionBitMask后，当接触到敌人时，两者会互相弹开；如果不想要这种效果，将值设为0。
        //enemy.physicsBody?.collisionBitMask = 0
    }
    
    
    //首先创建一个固定数值推动力的CGVector，规定monkey跳起的距离。我也是尝试了多次才总结出具体数值的。
    //用applyImpulse()制造推力，再转化为线速度和角速度推力。理论上，monkey在穿行太空的时候还会旋转，所以刚刚才要将physics body设定为不旋转。
    func jumpPlayer() {
        let impulse =  CGVector(dx: 0, dy: 30);player.physicsBody?.applyImpulse(impulse)
    }

    
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // 1如果游戏还没结束，monkey还处于非动态（受物理引擎控制），同样说明新游戏还没开始。这时将dynamic设置为true，隐藏label，大批敌人开始出现在屏幕上。
        if (!gameOver) {
            
            
            
            //!!!!!!!!!!!!!!!!!!!!
            //!!!!!!!!!!!!!!!!!!!!
            //!!!!!!!!!!!!!!!!!!!!
            //!!!!!!!!!!!!!!!!!!!!
            //本判断恒为假  不工作！
            if player.physicsBody?.dynamic == false {
                player.physicsBody?.dynamic = true
                //touchToBeginLabel.removeFromParent();
                touchToBeginLabel.hidden = true
                backgroundColor = SKColor.blackColor()
                
                runAction(SKAction.repeatActionForever(
                    SKAction.sequence([
                        SKAction.runBlock(spawnEnemy),
                        SKAction.waitForDuration(1.0)])))
            }
            // 2不管怎样都要调用 jumpPlayer ，因为只有dynamic 设置为true的时候，它才能被调用。
            jumpPlayer()
            
        }
            // 3如果游戏结束了，要重新开始，那么创建一个新的GameScene ，显示在屏幕上。
        else if (gameOver) {
            let newScene = GameScene(size: size)
            newScene.scaleMode = scaleMode  
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)  
            view?.presentScene(newScene, transition: reveal)  
        }  
    }

    
// MARK:移除离开画面的敌人
 func updateEnemy(enemy: SKNode) {
        //1
        if enemy.position.x < 0 {
            //2
        enemy.removeFromParent()
            //3 
            runAction(coinSound)
            //4 
            numPoints++
            //5
            points.text = "\(numPoints)"
        }
    }
    
    func endGame() {
        // 1
        gameOver = true
        // 2
        removeAllActions()
        // 3
        runAction(explosionSound)
        
        // 4
        endLabel.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        endLabel.fontColor = UIColor.whiteColor()
        endLabel.fontSize = 50
        endLabel2.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2 + endLabel.fontSize)
        endLabel2.fontColor = UIColor.whiteColor()
        endLabel2.fontSize = 20
        points.fontColor = UIColor.whiteColor()
        addChild(endLabel)  
        addChild(endLabel2)
        
        player.physicsBody?.dynamic = false
    }
    
    override func update(currentTime: CFTimeInterval) {
        //1
        if !gameOver {
            touchToBeginLabel.hidden=true;
            //2高度小于0结束游戏
            if player.position.y <= -50 {
                endGame()
            }
            //3
            
            enumerateChildNodesWithName("enemy") {
                enemy, _ in
                //4
                if enemy.position.x <= 0 {
                    //5  
                    self.updateEnemy(enemy)  
                }  
            }  
        }  
    }
    
 
}