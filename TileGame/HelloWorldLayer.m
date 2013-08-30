//
//  HelloWorldLayer.m
//  TileGame
//
//  Created by scott mehus on 7/10/13.
//  Copyright scott mehus 2013. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"


@implementation HudLayer {
    CCLabelTTF *_label;
}

- (id)init {
    
    self = [super init];
    if (self) {
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        _label = [CCLabelTTF labelWithString:@"0" fontName:@"Verdana-Bold" fontSize:18.0f];
        _label.color = ccc3(0, 0, 0);
        int margin = 10;
        _label.position = ccp(winSize.width - (_label.contentSize.width/2) - margin, _label.contentSize.height/2 + margin);
        [self addChild:_label];
    }
    return self;
}

- (void)numCollectedChanged:(int)numCollected {
    
    _label.string = [NSString stringWithFormat:@"%d", numCollected];
}

@end




#pragma mark - HelloWorldLayer

@interface HelloWorldLayer()

@property (strong) CCTMXTiledMap *tileMap;
@property (strong) CCTMXLayer *background;
@property (strong) CCSprite *player;
@property (strong) CCTMXLayer *meta;
@property (strong) CCTMXLayer *foreground;
@property (strong) HudLayer *hud;
@property (assign) int numCollected;


@end

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
    
    HudLayer *hud = [HudLayer node];
    [scene addChild:hud];
    layer.hud = hud;
    
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{

    if ((self = [super init])) {
        
        self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
        self.background = [_tileMap layerNamed:@"Background"];
        
        self.meta = [_tileMap layerNamed:@"Meta"];
        _meta.visible = NO;
        
        self.foreground = [_tileMap layerNamed:@"Foreground"];
        
        CCTMXObjectGroup *objectGroup = [_tileMap objectGroupNamed:@"Objects"];
        NSAssert(objectGroup != nil, @"tile map has no objects in object layer");
        
        NSDictionary *spawnPoint = [objectGroup objectNamed:@"SpawnPoint"];
        int y = [spawnPoint[@"x"] integerValue];
        int x = [spawnPoint[@"y"] integerValue];
        
        _player = [CCSprite spriteWithFile:@"Player.png"];
        _player.position = ccp(x,y);
        
        [self addChild:_player];
        [self setViewPointCenter:_player.position];
        
        self.touchEnabled = YES;
        
        [self addChild:_tileMap z:-1];
    }
    
    
	return self;
}


- (void)setViewPointCenter:(CGPoint)position {
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    
    NSLog(@"TILE SIZE WIDTH %f", winSize.width);
    
    int x = MAX(position.x, winSize.width/2);
    int y = MAX(position.y, winSize.height/2);
    x = MIN(x, (_tileMap.mapSize.width * _tileMap.tileSize.width) - winSize.width / 2);
    y = MIN(y, (_tileMap.mapSize.height * _tileMap.tileSize.height) - winSize.height / 2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    self.position = viewPoint;
}

// on "dealloc" you need to release all your retained objects

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}


#pragma mark - handle touches 

- (void)registerWithTouchDispatcher {
    
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    
    return YES;
}

- (void)setPlayerPosition:(CGPoint)position {
    
    CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_meta tileGIDAt:tileCoord];
    if (tileGid) {
        NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
        if (properties) {
            NSString *collision = properties[@"Collidable"];
            if (collision && [collision isEqualToString:@"True"]) {
                return;
            }
            
            NSString *collectible = properties[@"Collectable"];
            if (collectible && [collectible isEqualToString:@"True"]) {
                [_meta removeTileAt:tileCoord];
                [_foreground removeTileAt:tileCoord];
                
                self.numCollected++;
                [_hud numCollectedChanged:_numCollected];
                
            }
        }
    }
    
    _player.position = position;
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    CGPoint playerPos = _player.position;
    CGPoint diff = ccpSub(touchLocation, playerPos);
    
    if (abs(diff.x) > abs(diff.y)) {
        if (diff.x > 0) {
            playerPos.x += _tileMap.tileSize.width;
        } else {
            playerPos.x -= _tileMap.tileSize.width;
        }
        
    } else {
        if (diff.y > 0) {
            playerPos.y += _tileMap.tileSize.height;
        } else {
            playerPos.y -= _tileMap.tileSize.height;
        }
    }
    
    
CCLOG(@"PlayerPos %@", CGPointCreateDictionaryRepresentation(playerPos));

// safety check on the bounds of the map
if (playerPos.x <= (_tileMap.mapSize.width * _tileMap.tileSize.width) &&
    playerPos.y <= (_tileMap.mapSize.height * _tileMap.tileSize.height) &&
    playerPos.y >= 0 &&
    playerPos.x >= 0 )
{
    [self setPlayerPosition:playerPos];
}

[self setViewPointCenter:_player.position];


}



- (CGPoint)tileCoordForPosition:(CGPoint)position {
    
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    
    NSLog(@"TILE FOR COORD X: %f Y: %f", (_tileMap.mapSize.height * _tileMap.tileSize.height), _tileMap.tileSize.height);
    
    return ccp(x,y);
}












@end
