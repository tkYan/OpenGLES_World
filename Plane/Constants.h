//
//  Constants.h
//  Plane
//
//  Created by Peng, Yan on 6/13/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#ifndef Plane_Constants_h
#define Plane_Constants_h

#define STARTING_Z 6
#define RotateFactor 0.01
#define MinScaleFactor 0.5
#define MaxScaleFactor 1.5
#define MAX_ROW 50
#define MAX_COL 50
#define Sensitivity 0.8
#define VelocityFactor 0.04
#define SWITCH_SHAPE_DURATION 1000
#define PARTICLE_MOVE_DURATION 5000
#define DEFAULT_ANIMATION_TIME 2

#define PLANE_WIDTH_HEIGHT_RATIO    2
#define SPHERE_RADIUS               1
#define PLANE_HEIGHT (2 * SPHERE_RADIUS)

#define NUM_OF_VERTEX_FOR_PLANE 4
#define BACKGROUND_PLANE_SIZE   (12 * SPHERE_RADIUS)

#define BEZIER_CURVE_STEPS 25
#define NUM_OF_POINTS_IN_ONE_LINE (BEZIER_CURVE_STEPS + 1)
#define NUM_OF_PARTICLES_IN_ONE_LINE 3

#define Particle_Size 0.2

#define SAFE_FREE(x) {free(x); x = nil;}

typedef enum {
	Sphere = 0,
	Plane
} ShapeType;

typedef enum {
	Path = 0,
	Bar
} MetricType;

typedef struct {
	float lat;
	float lon;
} countryInfo;

static const countryInfo country[] = {-23.550, -46.6333,    //Sao Paulo
                                    38.8951, -77.0367,      //Washington
                                    52.5167, 13.3833,       //Berlin
                                    45.4214, -75.6919,      //Ottawa
                                    -33.55,  151.17,        //Sydney
                                    37.5665, 126.9780,      //Seoul
                                    48.8567, 2.3508,        //Pairs
                                    35.6895, 139.6917,      //Tokyo
                                    51.5072, -0.1275,       //London
                                    -30, 25,                //South Africa
                                    39.9139, 116.3917};     //Bei Jing

//test
typedef struct {
	float h;
	float s;
	float l;
} HSL;

#endif
