#import "GameView.h"
#import "mapData.h"
#import "tileData.h"
#define kAccelerometerFrequency        10 //Hz
@implementation GameView
- (id)initWithFrame:(CGRect)frame{
	if (self = [super initWithFrame:frame])
	{
	}
	return self;
}
-(void)configureAccelerometer{
	UIAccelerometer*  theAccelerometer = [UIAccelerometer sharedAccelerometer];
	
	if(theAccelerometer)
	{
		theAccelerometer.updateInterval = 1 / kAccelerometerFrequency;
		theAccelerometer.delegate = self;
	}
	else
	{
		NSLog(@"Oops we're not running on the device!");
	}
}
- (void) awakeFromNib{
	currentview = 0;
	talkOn = NO;
	twoFingers = NO;
	playerData = [[PlayerData alloc] init];
	damageEffects = [[NSMutableArray arrayWithCapacity: NSNotFound] retain];
	
	//Load all character Sprites
	npcSprites = [[NSMutableArray arrayWithCapacity: NSNotFound] retain];
	for (int e = 0;e > -1;e += 1) {
		UIImage* npcSpriteFile = [self loadImage:[NSString stringWithFormat:@"Npc %d",e] type:@"png"];
		if (npcSpriteFile != nil) {
			[npcSprites addObject:npcSpriteFile];
		} else {
			e= -2;
		}
	}
	//End load all character Sprites
	
	//Load all maps
	[self loadmaps];
	
	//***LOAD Interface IMAGE TO DRAW	
	interfaceImageObj[0] = [self loadImage:@"mainmenu" type:@"png"];
	interfaceImageObj[1] = [self loadImage:@"background" type:@"png"];
	interfaceImageObj[2] = [self loadImage:@"instructions" type:@"png"];
	interfaceImageObj[3] = [self loadImage:@"options" type:@"png"];
	interfaceImageObj[4] = [self loadImage:@"credits" type:@"png"];
	talkImage = [self loadImage:@"event" type:@"png"];
	//***END LOAD IMAGE
	
	//***LOAD Player TO DRAW
	mapPos = CGPointMake(0, 3);
	playerData.playerTilePos = CGPointMake(2,3);
	playerData.sprite = 1;
	//***END LOAD IMAGE
	
	// You have to explicity turn on multitouch for the view
	self.multipleTouchEnabled = YES;
	
	// configure for accelerometer
	[self configureAccelerometer];
	
	//***Turn on Game Timer
	gameTimer = [NSTimer scheduledTimerWithTimeInterval: 0.02
												 target: self
											   selector: @selector(handleGameTimer:)
											   userInfo: nil
												repeats: YES];
}
- (void) handleGameTimer: (NSTimer *) gameTimer {
	BOOL updateScreen = FALSE;
	
	MapData *currentMap = [maps objectAtIndex:playerData.currentMap - 1];
	NSArray *tiles = currentMap.mapTiles;
	
	//Control touch input for player
	if (touchedScreen.x != -1) {
		if (currentview == 0) {  //Main Menu
			//Play Button
			if (touchedScreen.x >= 115 && touchedScreen.x <= 210 && touchedScreen.y >= 60 && touchedScreen.y <= 105) {currentview = 1;}
			//Instructions Button
			if (touchedScreen.x >= 55 && touchedScreen.x <= 255 && touchedScreen.y >= 110 && touchedScreen.y <= 145) {currentview = 2;}
			//Options Button
			if (touchedScreen.x >= 95 && touchedScreen.x <= 220 && touchedScreen.y >= 150 && touchedScreen.y <= 180) {currentview = 3;}
			//Credits Button
			if (touchedScreen.x >= 100 && touchedScreen.x <= 215 && touchedScreen.y >= 190 && touchedScreen.y <= 225) {currentview = 4;}
			//To GMG Button
			if (touchedScreen.x >= 5 && touchedScreen.x <= 315 && touchedScreen.y >= 335 && touchedScreen.y <= 355) {[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.gamemakersgarage.com"]];}
		} else
			if (currentview == 1 && !talkOn) {  //Gameplay Screen
				CGPoint playerTilePos = playerData.playerTilePos;
				TileData *thisTile = [[tiles objectAtIndex:playerTilePos.x] objectAtIndex:playerTilePos.y];
				//Arrow Pad Buttons
				//RIGHT BUTTON
				if (touchedScreen.x >= 50 && touchedScreen.x <= 75 && touchedScreen.y >= 430 && touchedScreen.y <= 470) {
					if (thisTile.warpLeaveToRightMap != -1) {
						playerData.currentMap = thisTile.warpLeaveToRightMap;
						playerTilePos = thisTile.warpLeaveToRight;
					} else
						if (playerTilePos.x + 1.0 < [tiles count]) {
							TileData *tileToGo = [[tiles objectAtIndex:playerTilePos.x + 1.0] objectAtIndex:playerTilePos.y];
							if (tileToGo.blocked == 0 && tileToGo.npcOn == 0) {
								if (tileToGo.warpWhenHitToMap == -1) {playerTilePos.x += 1.0; } else {
									playerData.currentMap = tileToGo.warpWhenHitToMap;
									playerTilePos = tileToGo.warpWhenHitTo;
								}
							} else if (tileToGo.npcOn == 1) {
								//Find NPC
								for (int i = 0; i <= [currentMap.npcData count]-1; i+=1) {
									NpcData* npcCollided = [currentMap.npcData objectAtIndex:i];
									CGPoint npcPos = npcCollided.position;
									if (npcPos.x == playerTilePos.x + 1.0 && npcPos.y == playerTilePos.y) {
										[self playerCollision:npcCollided];
									}
								}
							}
						}
				} 
				//LEFT BUTTON
				else if (touchedScreen.x >= 48 && touchedScreen.x <= 75 && touchedScreen.y >= 364 && touchedScreen.y <= 400) {
					if (thisTile.warpLeaveToLeftMap != -1) {
						playerData.currentMap = thisTile.warpLeaveToLeftMap;
						playerTilePos = thisTile.warpLeaveToLeft;
					} else
						if (playerTilePos.x - 1.0 > -1) {
							TileData *tileToGo = [[tiles objectAtIndex:playerTilePos.x - 1.0] objectAtIndex:playerTilePos.y];
							if (tileToGo.blocked==0 && tileToGo.npcOn == 0) {
								if (tileToGo.warpWhenHitToMap == -1) {playerTilePos.x -= 1.0; } else {
									playerData.currentMap = tileToGo.warpWhenHitToMap;
									playerTilePos = tileToGo.warpWhenHitTo;
								}
							} else if (tileToGo.npcOn == 1) {
								//Find NPC
								for (int i = 0; i <= [currentMap.npcData count]-1; i+=1) {
									NpcData* npcCollided = [currentMap.npcData objectAtIndex:i];
									CGPoint npcPos = npcCollided.position;
									if (npcPos.x == playerTilePos.x - 1.0 && npcPos.y == playerTilePos.y) {
										[self playerCollision:npcCollided];
									}
								}
							}
						}
				}
				//UP BUTTON
				else if (touchedScreen.x >= 75 && touchedScreen.x <= 110 && touchedScreen.y >= 400 && touchedScreen.y <= 430) {
					if (thisTile.warpLeaveToUpMap != -1) {
						playerData.currentMap = thisTile.warpLeaveToUpMap;
						playerTilePos = thisTile.warpLeaveToUp;
					} else
						if (playerTilePos.y - 1.0 > -1) {
							TileData *tileToGo = [[tiles objectAtIndex:playerTilePos.x] objectAtIndex:playerTilePos.y - 1.0];
							if (tileToGo.blocked==0 && tileToGo.npcOn == 0) {
								if (tileToGo.warpWhenHitToMap == -1) {playerTilePos.y -= 1.0; } else {
									playerData.currentMap = tileToGo.warpWhenHitToMap;
									playerTilePos = CGPointMake(tileToGo.warpWhenHitTo.x,tileToGo.warpWhenHitTo.y);
								}
							} else if (tileToGo.npcOn == 1) {
								//Find NPC
								for (int i = 0; i <= [currentMap.npcData count]-1; i+=1) {
									NpcData* npcCollided = [currentMap.npcData objectAtIndex:i];
									CGPoint npcPos = npcCollided.position;
									if (npcPos.x == playerTilePos.x && npcPos.y == playerTilePos.y - 1.0) {
										
										[self playerCollision:npcCollided];
									}
								}
							}
						}
				}
				//Down BUTTON
				else if (touchedScreen.x >= 10 && touchedScreen.x <= 50 && touchedScreen.y >= 405 && touchedScreen.y <= 430) {
					if (thisTile.warpLeaveToDownMap != -1) {
						playerData.currentMap = thisTile.warpLeaveToDownMap;
						playerTilePos = thisTile.warpLeaveToDown;
					} else
						if (playerTilePos.y + 1.0 < [[tiles objectAtIndex:playerTilePos.x] count]) {
							TileData *tileToGo = [[tiles objectAtIndex:playerTilePos.x] objectAtIndex:playerTilePos.y + 1.0];
							if (tileToGo.blocked==0 && tileToGo.npcOn == 0) {
								if (tileToGo.warpWhenHitToMap == -1) {playerTilePos.y += 1.0; } else {
									playerData.currentMap = tileToGo.warpWhenHitToMap;
									playerTilePos = tileToGo.warpWhenHitTo;
								}
							} else if (tileToGo.npcOn == 1) {
								//Find NPC
								for (int i = 0; i <= [currentMap.npcData count]-1; i+=1) {
									NpcData* npcCollided = [currentMap.npcData objectAtIndex:i];
									CGPoint npcPos = npcCollided.position;
									if (npcPos.x == playerTilePos.x && npcPos.y == playerTilePos.y + 1.0) {
										[self playerCollision:npcCollided];
									}
								}
							}
						}
				}
				//Toggle BUTTON
				else if (touchedScreen.x >= 140 && touchedScreen.x <= 180 && touchedScreen.y >= 365 && touchedScreen.y <= 462) {
					if (playerData.displayToggle == 1) {
						playerData.displayToggle = 0;} else
							if (playerData.displayToggle == 0)
							{playerData.displayToggle = 1;}
				}
				playerData.playerTilePos = playerTilePos;
				
			} else
				if (currentview == 2 || currentview == 3 || currentview == 4) {
					//Back to main menu button
					if (touchedScreen.x >= 20 && touchedScreen.x <= 145 && touchedScreen.y >= 435 && touchedScreen.y <= 456) {currentview = 0;} 
				} else if (currentview == 1 && talkOn) {
					//Event/Talk button code
					if (talkOn) {
						talkOn = NO;
					}
				}
		touchedScreen.x = -1;
		updateScreen =TRUE;
	}
	
	//Control all game elements
	currentMap = [maps objectAtIndex:playerData.currentMap - 1];
	tiles = currentMap.mapTiles;
	if (currentview == 1 && !talkOn) { //Gameplay Screen
		//NPCs
		for (int i = 0; i < [currentMap.npcData count]; i +=1) {
			NpcData* npcToProcess = [currentMap.npcData objectAtIndex:i];
			//NPC Move Timer
			if (npcToProcess.moveTimer != npcToProcess.moveCount) {npcToProcess.moveTimer += 1;} else
				if (npcToProcess.moveTimer == npcToProcess.moveCount) {
					npcToProcess.moveTimer = 0;
					//**Run NPC targeting code
					if (npcToProcess.movStyle == 1) {//Target/Follow Object
						if (npcToProcess.target == -1) {
							//Target player to move towards
							if (playerData.hp > 0) {npcToProcess.target = -2;}
						}
					} else if (npcToProcess.movStyle == 2) {
						if (npcToProcess.target == -1) {
							int randomnum = arc4random() % 2;
							if (randomnum == 0) {
								//Target player to move towards
								if (playerData.hp > 0) {npcToProcess.target = -2;}
							} else {
								if ([currentMap.npcData count]-1 > 0) {
								int targetnpc = arc4random() % ([currentMap.npcData count]-1);
								if (targetnpc >= i) {targetnpc += 1;}
								NpcData* targetNpc = [currentMap.npcData objectAtIndex:targetnpc];
								if (targetNpc.hp > 0) {npcToProcess.target = targetnpc;}
								}
							}
						}
					} else if (npcToProcess.movStyle == 3) {
						if (npcToProcess.target == -1) {
							if ([currentMap.npcData count]-1 > 0) {
							int targetnpc = arc4random() % ([currentMap.npcData count]-1);
							if (targetnpc >= i) {targetnpc += 1;}
							NpcData* targetNpc = [currentMap.npcData objectAtIndex:targetnpc];
							
							if (targetNpc.hp > 0) {npcToProcess.target = targetnpc;}
							}
						}
					}
					//**End NPC targeting code
					[self moveNpc:npcToProcess currentMapTiles:tiles allNpcs:currentMap.npcData];
					if (npcToProcess.aggressive == 1) {[self npcAttack:npcToProcess currentMapTiles:tiles allNpcs:currentMap.npcData];}
					updateScreen = TRUE;
				}
			//Check for npc death
			if (npcToProcess.hp <= 0) {
				int npcnum = [currentMap.npcData count];
				[self npcDeath:i mapOfNpc:playerData.currentMap - 1];
				if (npcnum < [currentMap.npcData count]) {i -= 1;}
			}
		}
		//Check for player death
		if (playerData.hp <= 0) {[self playerDeath];}
		
		//Check for drawing damage
		if ([damageEffects count] > 0) {updateScreen = YES;}
		
		//****TEST FOR PERFORMANCE PURPOSES ONLY UNLESS OTHERWISE APPROVED
		updateScreen = YES;
		//****TEST FOR PERFORMANCE PURPOSES ONLY UNLESS OTHERWISE APPROVED
	}
	else if (currentview == 0 || currentview == 2 || currentview == 3 || currentview == 4) {} 
	
	if (updateScreen) {[self setNeedsDisplay];}
} // handleTimer
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration{
	//	UIAccelerationValue x, y, z;
	//	x = acceleration.x;
	//	y = acceleration.y;
	//	z = acceleration.z;
	
	// Do something with the values.
	//	xField.text = [NSString stringWithFormat:@"%.5f", x];
	//	yField.text = [NSString stringWithFormat:@"%.5f", y];
	//	zField.text = [NSString stringWithFormat:@"%.5f", z];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	UITouch *touch = [touches anyObject];
	NSUInteger tapCount = [touch tapCount];
	CGPoint location = [touch locationInView:self];
	
	if([touches count] > 1)
	{
		twoFingers = YES;
	}
	
	// tell the view to redraw
	//[self setNeedsDisplay];
}
- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event{
	UITouch *touch = [touches anyObject];
	NSUInteger tapCount = [touch tapCount];
	CGPoint location = [touch locationInView:self];
	if([touches count] > 1)
	{
		twoFingers = YES;
	}
	if (twoFingers) {
	} else {
	}
	
	// tell the view to redraw
	//[self setNeedsDisplay];
}
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	UITouch *touch = [touches anyObject];
	NSUInteger tapCount = [touch tapCount];
	CGPoint location = [touch locationInView:self];
	touchedScreen = location;
	// reset the var
	twoFingers = NO;
	// tell the view to redraw
	//[self setNeedsDisplay];
}
- (void) drawRect:(CGRect)rect{
	//DEFINE THE SCREEN'S DRAWING CONTEXT
	CGContextRef context;
	
	if (currentview == 1) {
		[self drawImage:context translateX:320 translateY:0 image:interfaceImageObj[currentview] point:CGPointMake(0, 0) rotation:90 * M_PI / 180];
	} else {
		[self drawImage:context translateX:0 translateY:0 image:interfaceImageObj[currentview] point:CGPointMake(0, 0) rotation:0];
	}
	//DRAW STRING -> [@"Hello" drawAtPoint:CGPointMake(0.0f, 0.0f) withFont:[UIFont fontWithName:@"Helvetica" size:12]];
	
	[self drawImage:context translateX:0 translateY:0 image:interfaceImageObj[currentview] point:CGPointMake(0, 0) rotation:90 * M_PI / 180];
	
	if (currentview == 0) { //Main Menu
	} else
		if (currentview == 1) { //Gameplay Screen
			MapData *currentmap = [maps objectAtIndex:playerData.currentMap - 1];
			[self drawImage:context translateX:320 translateY:0 image:currentmap.mapImageFile point:mapPos rotation:90 * M_PI / 180];
			
			//**Draw ALL NPCs
			NSMutableArray* npcs = currentmap.npcData;
			for(int i = 0; i < [npcs count]; i += 1) 
			{
				NpcData* currentNpc = [npcs objectAtIndex:i];
				CGPoint npcPosition = currentNpc.position;
				[self drawImage:context translateX:320 translateY:0 image:currentNpc.npcImageObj point:CGPointMake(npcPosition.x*45.0 + mapPos.x, npcPosition.y*45.0 + mapPos.y) rotation:90 * M_PI / 180];
				if (currentNpc.hp < currentNpc.hpmax) {
					float rectcolor[4] = {1.0,0.0,0.0,1.0};
					[self drawRectangle:context translateX:320 translateY:0 point:CGPointMake((npcPosition.x + .06)*45.0 + mapPos.x, (npcPosition.y+.95)*45.0 + mapPos.y) widthheight:CGPointMake((.9)*45.0, (.1)*45.0) color:rectcolor rotation:90 * M_PI / 180];
					rectcolor[0] = 0.0;
					rectcolor[1] = 1.0;
					[self drawRectangle:context translateX:320 translateY:0 point:CGPointMake((npcPosition.x + .06)*45.0 + mapPos.x, (npcPosition.y+.95)*45.0 + mapPos.y) widthheight:CGPointMake((.9)*45.0*currentNpc.hp/currentNpc.hpmax, (.1)*45.0) color:rectcolor rotation:90 * M_PI / 180];
				}
			}
			
			[self drawImage:context translateX:320 translateY:0 image:[npcSprites objectAtIndex:playerData.sprite] point:CGPointMake(playerData.playerTilePos.x*45.0 + mapPos.x,playerData.playerTilePos.y*45.0 + mapPos.y) rotation:90 * M_PI / 180];
			if (playerData.hp < playerData.hpmax) {
				float rectcolor[4] = {1.0,0.0,0.0,1.0};
				[self drawRectangle:context translateX:320 translateY:0 point:CGPointMake((playerData.playerTilePos.x + .06)*45.0 + mapPos.x, (playerData.playerTilePos.y+.95)*45.0 + mapPos.y) widthheight:CGPointMake((.9)*45.0, (.1)*45.0) color:rectcolor rotation:90 * M_PI / 180];
				rectcolor[0] = 0.0;
				rectcolor[1] = 1.0;
				[self drawRectangle:context translateX:320 translateY:0 point:CGPointMake((playerData.playerTilePos.x + .06)*45.0 + mapPos.x, (playerData.playerTilePos.y+.95)*45.0 + mapPos.y) widthheight:CGPointMake((.9)*45.0*playerData.hp/playerData.hpmax, (.1)*45.0) color:rectcolor rotation:90 * M_PI / 180];
			}
			//Draw Damage stats
			for (int i = 0; i < [damageEffects count]; i += 1) {
				DamageEffect* damage = [damageEffects objectAtIndex:i];
				damage.ticks += 0.1;
				[self drawString:context translateX:320 translateY:0 text:damage.text point:CGPointMake((damage.position.x+.5)*45.0, (damage.position.y+.5 - (damage.ticks/damage.ticksMax*0.6))*45.0) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica" size:16] color:damage.color.CGColor];
				if (damage.ticks >= damage.ticksMax) {[damageEffects removeObjectAtIndex:i]; i-=1;}
			}
			CGColorRef textcolor = [UIColor whiteColor].CGColor;
			//Draw Stats
			if (playerData.displayToggle == 0) {
				
				[self drawString:context translateX:320 translateY:0 text:@"Stats" point:CGPointMake(395,5) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica" size:18] color:textcolor];
				[self drawString:context translateX:320 translateY:0 text:[NSString stringWithFormat:@"HP: %d/%d",playerData.hp,playerData.hpmax] point:CGPointMake(375,40) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica" size:14] color:textcolor];
				[self drawString:context translateX:320 translateY:0 text:[NSString stringWithFormat:@"MP: %d/%d",playerData.mp,playerData.mpmax] point:CGPointMake(375,57) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica" size:14] color:textcolor];
				[self drawString:context translateX:320 translateY:0 text:[NSString stringWithFormat:@"LVL: %d",playerData.lvl] point:CGPointMake(375,74) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica" size:14] color:textcolor];
				[self drawString:context translateX:320 translateY:0 text:[NSString stringWithFormat:@"EXP: %d",playerData.exp] point:CGPointMake(375,91) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica" size:14] color:textcolor];
				[self drawString:context translateX:320 translateY:0 text:[NSString stringWithFormat:@"Gold: %d",playerData.gold] point:CGPointMake(375,108) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica" size:14] color:textcolor];
			} else if (playerData.displayToggle == 1) {
				[self drawString:context translateX:320 translateY:0 text:@"Inventory" point:CGPointMake(380,5) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica" size:18] color:textcolor];
				[self drawString:context translateX:320 translateY:0 text:@"No Weapon" point:CGPointMake(375,40) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica-Oblique" size:14] color:textcolor];
				[self drawString:context translateX:320 translateY:0 text:@"No Armor" point:CGPointMake(375,57) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica-Oblique" size:14] color:textcolor];
				[self drawString:context translateX:320 translateY:0 text:@"No Trinket" point:CGPointMake(375,74) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica-Oblique" size:14] color:textcolor];
				[self drawString:context translateX:320 translateY:0 text:@"0 Potions" point:CGPointMake(375,108) rotation:90 * M_PI / 180 font:[UIFont fontWithName:@"Helvetica" size:14] color:textcolor];
			}
			
			//Draw talk window if open
			if (talkOn) {
			[self drawImage:context translateX:320 translateY:0 image:talkImage point:CGPointMake(mapPos.x - talkImage.size.width/2 + currentmap.mapImageFile.size.width/2, mapPos.y - talkImage.size.height/2 + currentmap.mapImageFile.size.height/2) rotation:90 * M_PI / 180];
			}
		} else
			if (currentview == 2) { //Instructions Screen
			} else
				if (currentview == 3) { //Options Screen
				} else
					if (currentview == 4) { //Credits Screen
					}
}
- (UIImage*)loadImage:(NSString *)name type:(NSString*)imageType {
	NSString* filePath = [[NSBundle mainBundle] pathForResource:name ofType:imageType];
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
	if (fileExists) {
		UIImage* imageFile = [[UIImage alloc] initWithContentsOfFile:filePath];
		return imageFile;
	} else {
		return nil;
	}
}
- (NSString*)loadText:(NSString *)name type:(NSString*)fileType  {
	NSString* filePath = [[NSBundle mainBundle] pathForResource:name ofType:fileType];
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
	if (fileExists) {
		NSString* txtFile = [[NSString alloc] initWithContentsOfFile:filePath];
		return txtFile;
	} else {
		return nil;
	}
}
- (void) drawImage:(CGContextRef)context translateX:(int)translateX translateY:(int)translateY image:(UIImage*)sprite point:(CGPoint)point rotation:(float)rotation {
	//****INDIVIDUAL DRAW IMAGE PLAYER
	// Grab the drawing context
	context = UIGraphicsGetCurrentContext();
	// like Processing pushMatrix
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, translateX, translateY);
	// Uncomment to see the rotated square
	CGContextRotateCTM(context, rotation);
	//***DRAW THE IMAGE
	[sprite drawAtPoint:point];
	//***END DRAW THE IMAGE
	// like Processing popMatrix
	CGContextRestoreGState(context);
	//***END INDIVIDUAL DRAW IMAGE CODE
}
- (void) drawString:(CGContextRef)context translateX:(int)translateX translateY:(int)translateY text:(NSString*)text point:(CGPoint)point rotation:(float)rotation font:(UIFont*)font color:(CGColorRef)color {
	//****INDIVIDUAL DRAW IMAGE PLAYER
	// Grab the drawing context
	context = UIGraphicsGetCurrentContext();
	// like Processing pushMatrix
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, translateX, translateY);
	// Uncomment to see the rotated square
	CGContextRotateCTM(context, rotation);
	//Set the text color
	CGContextSetFillColorWithColor(context, color);
	//***DRAW THE Text
	[text drawAtPoint:point withFont:font];
	//***END DRAW THE IMAGE
	// like Processing popMatrix
	CGContextRestoreGState(context);
	//***END INDIVIDUAL DRAW IMAGE CODE
}
- (void) drawRectangle:(CGContextRef)context translateX:(int)translateX translateY:(int)translateY point:(CGPoint)point widthheight:(CGPoint)widthheight color:(float[4])color rotation:(float)rotation {
	//****INDIVIDUAL DRAW RECTANGLE CODE
	//Positions/Dimensions of rectangle
	CGRect theRect = CGRectMake(point.x, point.y, widthheight.x, widthheight.y);
	// Grab the drawing context
	context = UIGraphicsGetCurrentContext();
	// like Processing pushMatrix
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, translateX, translateY);
	// Uncomment to see the rotated square
	CGContextRotateCTM(context, rotation);
	// Set red stroke
	CGContextSetRGBFillColor(context, color[0], color[1], color[2], color[3]);
	// Draw a rect with a red stroke
	CGContextFillRect(context, theRect);
	//CGContextStrokeRect(context, theRect);
	// like Processing popMatrix
	CGContextRestoreGState(context);
	//***END INDIVIDUAL DRAW RECT CODE
}
- (void) moveNpc:(NpcData*)npcToProcess currentMapTiles:(NSArray*)tiles allNpcs:(NSArray*)allNpcs {
	int target = npcToProcess.target;
	CGPoint npcTilePosition = npcToProcess.position;
	TileData* npcTile = [[tiles objectAtIndex:npcTilePosition.x] objectAtIndex:npcTilePosition.y];
	if (target == -1) //RANDOM
	{
		int vertOrHorz = arc4random() % 2;
		int moveDirection = arc4random() % 2;
		if (moveDirection == 0) {moveDirection = -1;}
		if (vertOrHorz == 0) { //Vertical
			if (npcTilePosition.y + moveDirection >= 0 && npcTilePosition.y + moveDirection < [[tiles objectAtIndex:0] count]) {
				TileData *tileToGo = [[tiles objectAtIndex:npcTilePosition.x] objectAtIndex:npcTilePosition.y + moveDirection];
				if (tileToGo.npcOn==0 && tileToGo.blocked==0 && (playerData.playerTilePos.x != npcTilePosition.x || playerData.playerTilePos.y != npcTilePosition.y + moveDirection)) {
					npcTilePosition.y += moveDirection;
				}
			}
		} else { //Horizontal
			if (npcTilePosition.x + moveDirection >= 0 && npcTilePosition.x + moveDirection < [tiles count]) {
				TileData *tileToGo = [[tiles objectAtIndex:npcTilePosition.x + moveDirection] objectAtIndex:npcTilePosition.y];
				if (tileToGo.npcOn==0 && tileToGo.blocked==0 && (playerData.playerTilePos.x != npcTilePosition.x + moveDirection || playerData.playerTilePos.y != npcTilePosition.y)) {
					npcTilePosition.x += moveDirection;
				}
			}
		}
	} else //Move towards target
	{
		CGPoint targetPos;
		if (target == -2) {targetPos = playerData.playerTilePos;} else {
			NpcData* npcTarget = [allNpcs objectAtIndex:target];
			targetPos = npcTarget.position;}
		TileData* tilesAround[4] = {nil, nil, nil, nil}; //Up down left right
		if (npcTilePosition.y > 0) {tilesAround[0] = [[tiles objectAtIndex:npcTilePosition.x] objectAtIndex:npcTilePosition.y - 1];}
		if (npcTilePosition.y < 6) {tilesAround[1] = [[tiles objectAtIndex:npcTilePosition.x] objectAtIndex:npcTilePosition.y + 1];}
		if (npcTilePosition.x > 0) {tilesAround[2] = [[tiles objectAtIndex:npcTilePosition.x - 1] objectAtIndex:npcTilePosition.y];}
		if (npcTilePosition.x < 7) {tilesAround[3] = [[tiles objectAtIndex:npcTilePosition.x + 1] objectAtIndex:npcTilePosition.y];}
		BOOL moveableDirections[4] = {YES, YES, YES, YES}; //Up down left right
		if (tilesAround[0] == nil) {moveableDirections[0] = NO;}
		if (tilesAround[1] == nil) {moveableDirections[1] = NO;}
		if (tilesAround[2] == nil) {moveableDirections[2] = NO;}
		if (tilesAround[3] == nil) {moveableDirections[3] = NO;}
		
		//Place in movement restrictions
		CGPoint playerPos = playerData.playerTilePos;
		if (playerPos.x == npcTilePosition.x && playerPos.y == npcTilePosition.y - 1) {moveableDirections[0] = NO;}
		if (playerPos.x == npcTilePosition.x && playerPos.y == npcTilePosition.y + 1) {moveableDirections[1] = NO;}
		if (playerPos.x == npcTilePosition.x - 1 && playerPos.y == npcTilePosition.y) {moveableDirections[2] = NO;}
		if (playerPos.x == npcTilePosition.x + 1 && playerPos.y == npcTilePosition.y) {moveableDirections[3] = NO;}

		if (moveableDirections[0]) {moveableDirections[0] = !(tilesAround[0].blocked==1 || tilesAround[0].npcOn==1);}
		if (moveableDirections[1]) {moveableDirections[1] = !(tilesAround[1].blocked==1 || tilesAround[1].npcOn==1);}
		if (moveableDirections[2]) {moveableDirections[2] = !(tilesAround[2].blocked==1 || tilesAround[2].npcOn==1);}
		if (moveableDirections[3]) {moveableDirections[3] = !(tilesAround[3].blocked==1 || tilesAround[3].npcOn==1);}
		
		//Aim to move towards player, if can't, move randomly
		BOOL ablemovetotargetx = (targetPos.x < npcTilePosition.x && moveableDirections[2])||(targetPos.x > npcTilePosition.x && moveableDirections[3]);
		BOOL ablemovetotargety = (targetPos.y < npcTilePosition.y && moveableDirections[0])||(targetPos.y > npcTilePosition.y && moveableDirections[1]);
		int movedir = -1; // 0 = x, 1 = y
		if (ablemovetotargetx && ablemovetotargety) {movedir = arc4random() % 2;}
		else if (ablemovetotargetx) {movedir = 0;} else if (ablemovetotargety) {movedir = 1;}
		
		if (movedir == 0) {
			if (targetPos.x < npcTilePosition.x && moveableDirections[2]) {npcTilePosition.x -= 1;}
			if (targetPos.x > npcTilePosition.x && moveableDirections[3]) {npcTilePosition.x += 1;}
		} else if (movedir == 1) {
			if (targetPos.y < npcTilePosition.y && moveableDirections[0]) {npcTilePosition.y -= 1;}
			if (targetPos.y > npcTilePosition.y && moveableDirections[1]) {npcTilePosition.y += 1;}
		} else  //Move randomly as to get around barrier
			if (!(abs(targetPos.x - npcTilePosition.x) <= 1 && abs(targetPos.y - npcTilePosition.y) == 0) && !(abs(targetPos.x - npcTilePosition.x) == 0 && abs(targetPos.y - npcTilePosition.y) <= 1)) {
			int vertOrHorz = arc4random() % 2;
			int moveDirection = arc4random() % 2;
			if (moveDirection == 0) {moveDirection = -1;}
			if (vertOrHorz == 0) { //Vertical
				if (npcTilePosition.y + moveDirection >= 0 && npcTilePosition.y + moveDirection < [[tiles objectAtIndex:0] count]) {
					TileData *tileToGo = [[tiles objectAtIndex:npcTilePosition.x] objectAtIndex:npcTilePosition.y + moveDirection];
					if (tileToGo.npcOn==0 && tileToGo.blocked==0 && (playerData.playerTilePos.x != npcTilePosition.x || playerData.playerTilePos.y != npcTilePosition.y + moveDirection)) {
						npcTilePosition.y += moveDirection;
					}
				}
			} else { //Horizontal
				if (npcTilePosition.x + moveDirection >= 0 && npcTilePosition.x + moveDirection < [tiles count]) {
					TileData *tileToGo = [[tiles objectAtIndex:npcTilePosition.x + moveDirection] objectAtIndex:npcTilePosition.y];
					if (tileToGo.npcOn==0 && tileToGo.blocked==0 && (playerData.playerTilePos.x != npcTilePosition.x + moveDirection || playerData.playerTilePos.y != npcTilePosition.y)) {
						npcTilePosition.x += moveDirection;
					}
				}
			}
		}
	}
	npcTile.npcOn = 0;
	TileData *nowOn = [[tiles objectAtIndex:npcTilePosition.x] objectAtIndex:npcTilePosition.y];
	nowOn.npcOn = 1;
	npcToProcess.position = npcTilePosition;
}
- (void) npcAttack:(NpcData*)npcToProcess currentMapTiles:(NSArray*)tiles allNpcs:(NSArray*)allNpcs {
	CGPoint target;
	CGPoint npcPosition = npcToProcess.position;
	if (npcToProcess.target == -2) {
		target = playerData.playerTilePos;
		if (abs(target.x - npcPosition.x) <= 1 && abs(target.y - npcPosition.y) <= 1 && abs(target.x - npcPosition.x) != abs(target.y - npcPosition.y)) {
			playerData.hp -= 1;
			DamageEffect* damage = [[DamageEffect alloc] init];
			damage.position = CGPointMake(playerData.playerTilePos.x,playerData.playerTilePos.y);
			damage.text = @"-1";
			[damageEffects addObject:damage];
			if (playerData.hp <= 0) {npcToProcess.target = -1;}
		}
	} else if (npcToProcess.target >= 0) {
		NpcData* targetNpc = [allNpcs objectAtIndex:npcToProcess.target];
		target = targetNpc.position;
		if (abs(target.x - npcPosition.x) <= 1 && abs(target.y - npcPosition.y) <= 1 && abs(target.x - npcPosition.x) != abs(target.y - npcPosition.y)) {
			targetNpc.hp -= 1;
			DamageEffect* damage = [[DamageEffect alloc] init];
			damage.position = CGPointMake(target.x,target.y);
			damage.text = @"-1";
			[damageEffects addObject:damage];
			if (targetNpc.hp <= 0) {npcToProcess.target = -1;}
		}
	}
}
- (void) playerCollision:(NpcData*)npcCollided {
	if (npcCollided.aggressive == 1) {
		npcCollided.hp -= 1;
		DamageEffect* damage = [[DamageEffect alloc] init];
		damage.position = CGPointMake(npcCollided.position.x,npcCollided.position.y);
		damage.text = @"-1";
		[damageEffects addObject:damage];
	}
	if (npcCollided.collisionEvent > 0) {[self gameEvents:npcCollided];}
}
- (void) loadmaps {
	maps = [[NSMutableArray arrayWithCapacity: NSNotFound] retain];
	//LOAD Maps
	for (int i = 1; i > 0; i += 1) {
		UIImage* mapImageFile = [self loadImage:[NSString stringWithFormat:@"Map %d",i] type:@"png"];
		if (mapImageFile != nil) 
		{
			NSMutableArray* tiles = [[NSMutableArray arrayWithCapacity:8] retain];
			NSMutableArray* npcsToAdd = [[NSMutableArray alloc] init];
			
			//Create default "blank" tiles
			for (int e = 0; e < 8; e++) {
				NSMutableArray *row = [NSMutableArray arrayWithCapacity:7];
				
				for (int k = 0; k<7; k++) {
					TileData *loadTileData = [[TileData alloc] init];
					[row addObject:loadTileData];
				}
				
				[tiles addObject:row];
			}
			
			if (i == 1) {
				//Load NPCS for map
				[npcsToAdd addObject:[self loadnpcs:1 xpos:0 ypos:4]];
				[npcsToAdd addObject:[self loadnpcs:1 xpos:4 ypos:5]];
				//Load tiles for map
				TileData *tileFound;
				//Create warp to...
				for (int e = 0; e < 7; e += 1) {
					tileFound = [[tiles objectAtIndex:0] objectAtIndex:e];
					tileFound.warpLeaveToLeftMap = 2;
					tileFound.warpLeaveToLeft = CGPointMake(7, e);
					tileFound = [[tiles objectAtIndex:7] objectAtIndex:e];
					tileFound.warpLeaveToRightMap = 2;
					tileFound.warpLeaveToRight = CGPointMake(0, e);
				}
				for (int e = 0; e < 8; e += 1) {
					tileFound = [[tiles objectAtIndex:e] objectAtIndex:6];
					tileFound.warpLeaveToDownMap = 2;
					tileFound.warpLeaveToDown = CGPointMake(e, 0);
					tileFound = [[tiles objectAtIndex:e] objectAtIndex:0];
					tileFound.warpLeaveToUpMap = 2;
					tileFound.warpLeaveToUp = CGPointMake(e, 6);
				}
			} else if (i == 2) {
				//Load NPCS for map
				[npcsToAdd addObject:[self loadnpcs:2 xpos:1 ypos:3]];
				[npcsToAdd addObject:[self loadnpcs:2 xpos:6 ypos:3]];
				//Load tiles for map
				TileData *tileFound;
				//Create warp to...
				for (int e = 0; e < 7; e += 1) {
					tileFound = [[tiles objectAtIndex:0] objectAtIndex:e];
					tileFound.warpLeaveToLeftMap = 1;
					tileFound.warpLeaveToLeft = CGPointMake(7, e);
					tileFound = [[tiles objectAtIndex:7] objectAtIndex:e];
					tileFound.warpLeaveToRightMap = 1;
					tileFound.warpLeaveToRight = CGPointMake(0, e);
				}
				for (int e = 0; e < 8; e += 1) {
					tileFound = [[tiles objectAtIndex:e] objectAtIndex:6];
					tileFound.warpLeaveToDownMap = 1;
					tileFound.warpLeaveToDown = CGPointMake(e, 0);
					tileFound = [[tiles objectAtIndex:e] objectAtIndex:0];
					tileFound.warpLeaveToUpMap = 1;
					tileFound.warpLeaveToUp = CGPointMake(e, 6);
				}
				tileFound = [[tiles objectAtIndex:2] objectAtIndex:2];
				tileFound.blocked = 1;
				tileFound = [[tiles objectAtIndex:2] objectAtIndex:3];
				tileFound.blocked = 1;
				tileFound = [[tiles objectAtIndex:2] objectAtIndex:4];
				tileFound.blocked = 1;
				tileFound = [[tiles objectAtIndex:3] objectAtIndex:2];
				tileFound.blocked = 1;
				tileFound = [[tiles objectAtIndex:3] objectAtIndex:3];
				tileFound.blocked = 1;
				tileFound = [[tiles objectAtIndex:3] objectAtIndex:4];
				tileFound.blocked = 1;
			}
			//Make tiles know if npc is on them
			for (int e = 0; e < [npcsToAdd count]; e +=1) {
				NpcData* npcToProcess = [npcsToAdd objectAtIndex:e];
				CGPoint npcTilePosition = npcToProcess.position;
				TileData *npcTile = [[tiles objectAtIndex:npcTilePosition.x] objectAtIndex:npcTilePosition.y];
				npcTile.npcOn = 1;
			}
			
			//Create an empty map
			MapData *loadmapdata = [[MapData alloc] init];
			//Fill empty map
			loadmapdata.mapImageFile = mapImageFile;
			loadmapdata.mapTiles = tiles;
			loadmapdata.npcData = npcsToAdd;
			
			[maps addObject:loadmapdata];
		} else {i = -1;}
	}	
}
- (NpcData*) loadnpcs:(int)npcnum xpos:(int)xpos ypos:(int)ypos {
	//Create an empty NPC shell
	NpcData* newNpc = [[NpcData alloc] init];
	if (npcnum == 1) {
	//Get the type of NPC it's stated as
	//int typeOfNpc = [[individualMapAttributeData objectAtIndex:1] intValue];
	//Stick it where it's suppose to be on the map
	newNpc.position = CGPointMake(xpos,ypos);
	newNpc.moveCount = (arc4random() % 20) + 30; //150 50
	newNpc.moveTimer = 0;
	newNpc.movStyle = 2;
	newNpc.target = -1;
	newNpc.npcImageObj = [npcSprites objectAtIndex:0];
	newNpc.hp = 1;
	newNpc.hpmax = 1;
	newNpc.mp = 0;
	newNpc.mpmax = 0;
	newNpc.lvl = 0;
	newNpc.exp = 0;
		newNpc.collisionEvent = 1;
		newNpc.aggressive = 0;
	} else if (npcnum == 2) {
		newNpc.position = CGPointMake(xpos,ypos);
		newNpc.moveCount = (arc4random() % 40) + 20; //150 50
		newNpc.moveTimer = 0;
		newNpc.movStyle = 2;
		newNpc.target = -1;
		newNpc.npcImageObj = [npcSprites objectAtIndex:2];
		newNpc.hp = 20;
		newNpc.hpmax = 20;
		newNpc.mp = 0;
		newNpc.mpmax = 0;
		newNpc.lvl = 0;
		newNpc.exp = 0;
		newNpc.aggressive = 1;
	}
	return newNpc;
}
- (void) npcDeath:(int)deadNpc mapOfNpc:(int)mapnum {
	MapData* deathmap = [maps objectAtIndex:mapnum];
	NpcData* deadnpc = [deathmap.npcData objectAtIndex:deadNpc];
	[deadnpc.npcImageObj retain];
	CGPoint deadnpcpos = deadnpc.position;
	TileData* deathtile = [[deathmap.mapTiles objectAtIndex:deadnpcpos.x] objectAtIndex:deadnpcpos.y];
	deathtile.npcOn = 0;
	[deathmap.npcData removeObjectAtIndex:deadNpc];
	//remove traces of npc
	if ([deathmap.npcData count] > 0) {
	for(int i = 0; i <= [deathmap.npcData count] - 1; i += 1) {
		NpcData* updatenpc = [deathmap.npcData objectAtIndex:i];
		if (updatenpc.target == deadNpc) {updatenpc.target = -1;}
	}
	}
}
- (void) playerDeath {
	//Not decided yet
}
- (void) gameEvents:(NpcData*)eventNpc {
	switch(eventNpc.collisionEvent)
	{
		case 1:
			talkOn = YES;
			break;
		case 2:
			break;
		default:
			break;
	}
}
- (void) dealloc {
	[maps release];
	[gameTimer release];
	[super dealloc];
}
@end