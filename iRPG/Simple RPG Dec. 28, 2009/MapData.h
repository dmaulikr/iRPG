#import <Foundation/Foundation.h>
#import "tileData.h"
#import <UIKit/UIKit.h>
@class MapData;


@interface MapData : NSObject {
	UIImage* mapImageFile;
	NSArray *mapTiles;
	NSMutableArray* npcData;
};

-(void) dealloc;
@property(nonatomic, retain) UIImage *mapImageFile;
@property(nonatomic, retain) NSArray *mapTiles;
@property(nonatomic, retain) NSMutableArray *npcData;

@end