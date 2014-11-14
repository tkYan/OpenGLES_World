//
//  ParticlesManager.h
//  Plane
//
//  Created by Peng, Yan on 6/14/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "drawObjective.h"

@interface ParticlesManager : NSObject<drawObjective, switchShapeDelegate>

@property (nonatomic) GLKMatrix4 rotateMatrix;;

- (void)updateVertexWithOffset:(GLfloat)offset;

@end
