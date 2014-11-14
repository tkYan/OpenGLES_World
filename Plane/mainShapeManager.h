//
//  planeManager.h
//  Plane
//
//  Created by Peng, Yan on 3/19/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "drawObjective.h"

#define INDEX_NUMBER_FOR_EACH_RECT 6

typedef enum EnumPointPosition{
    LEFT_BOTTOM = 0,
    RIGHT_BOTTOM,
    RIGHT_TOP,
    LEFT_TOP
}EnumPointPosition;

@interface mainShapeManager : NSObject<drawObjective, switchShapeDelegate>

- (id) initWithRowCount:(NSUInteger)row ColumnCount:(NSUInteger)column;

- (void)freeResources;

@end
