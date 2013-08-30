//
//  HelloWorldLayer.h
//  TileGame
//
//  Created by scott mehus on 7/10/13.
//  Copyright scott mehus 2013. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

@interface HudLayer : CCLayer
- (void)numCollectedChanged:(int)numCollected;
@end

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer 
{
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
