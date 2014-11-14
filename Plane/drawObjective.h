//
//  drawObjective.h
//  Plane
//
//  Created by Peng, Yan on 6/13/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>
#import "Constants.h"

@protocol drawObjective <NSObject>

@property (nonatomic, assign) GLKBaseEffect *effect;
@property BOOL drawEnabled;

- (void)drawMainShapesWithModelViewMatrix:(GLKMatrix4)matrix;

- (void)generateBuffer;
- (void)releaseBuffer;

@end

@protocol switchShapeDelegate <NSObject>

@property (nonatomic) BOOL shapeSwitchAnimation;

- (void)switchShape:(ShapeType)type;
- (void) updateVertexForSwitchShapeAnimation:(NSTimeInterval)ratio;

@end
