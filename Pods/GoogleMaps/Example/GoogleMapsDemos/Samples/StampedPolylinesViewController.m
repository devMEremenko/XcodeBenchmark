/*
 * Copyright 2020 Google LLC. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "GoogleMapsDemos/Samples/StampedPolylinesViewController.h"

#import <GoogleMaps/GoogleMaps.h>

NS_ASSUME_NONNULL_BEGIN

static const double kSeattleLatitudeDegrees = 47.6089945;
static const double kSeattleLongitudeDegrees = -122.3410462;
static const double kZoom = 14;
static const double kStrokeWidth = 20;

/**
 * The following encoded path was constructed by using the Directions API.
 * This is the path from the Space Needle to Paramount Theatre, with the mode of transport
 * set to walking.
 * Please see the documentation https://developers.google.com/maps/documentation/directions
 * for more detail.
 */
static NSString *const kEncodedPathForWalkingDirections =
    @"ezsaHxkwiVLc@FQ?G@G@GDKBEPED?@@B@FOJSOUDIZk@?cB?w@?iA@yLAs@?IB?Ae@@_A?sACoA?EB??e@?u@A}A@{@`@"
    @"EBGv@_C\\aA?M?G@WHCFB|@kCRm@DQ?EDB@FZP?E@_@CC?oA?O\\i@j@mAN[DWd@GIq@BA?CBUVcAhA_CLUBDL_@@Bf@"
    @"eA`@o@|@iBCCRa@DD^aAf@{@`@}@Xc@GIVc@DDj@iANe@x@cBHUACRYNPZQHLDFDCVSB?CGKYHGr@s@r@g@v@o@"
    @"GUVSBC@FDJJK";

@implementation StampedPolylinesViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  GMSCameraPosition *defaultCamera = [GMSCameraPosition cameraWithLatitude:kSeattleLatitudeDegrees
                                                                 longitude:kSeattleLongitudeDegrees
                                                                      zoom:kZoom];

  GMSMapView *map = [GMSMapView mapWithFrame:self.view.bounds camera:defaultCamera];
  map.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:map];

  [self addTextureStampedPolylineToMap:map];
  [self addGradientTextureStampedPolylineToMap:map];
  [self addSpriteWalkingDotStampedPolylineToMap:map];
}

/**
 * Creates a texture stamped polyline and adds it to the supplied map.
 *
 * @param map The map to add the polyline to.
 */
- (void)addTextureStampedPolylineToMap:(GMSMapView *)map {
  GMSMutablePath *path = [GMSMutablePath path];
  [path addLatitude:kSeattleLatitudeDegrees + 0.003 longitude:kSeattleLongitudeDegrees - 0.003];
  [path addLatitude:kSeattleLatitudeDegrees - 0.005 longitude:kSeattleLongitudeDegrees - 0.005];
  [path addLatitude:kSeattleLatitudeDegrees - 0.007 longitude:kSeattleLongitudeDegrees + 0.001];

  UIImage *_Nonnull stamp = (UIImage *_Nonnull)[UIImage imageNamed:@"voyager"];
  GMSStrokeStyle *solidStroke = [GMSStrokeStyle solidColor:[UIColor redColor]];
  solidStroke.stampStyle = [GMSTextureStyle textureStyleWithImage:stamp];

  GMSPolyline *texturePolyline = [GMSPolyline polylineWithPath:path];
  texturePolyline.map = map;
  texturePolyline.strokeWidth = kStrokeWidth;
  texturePolyline.spans = @[ [GMSStyleSpan spanWithStyle:solidStroke] ];
}

/**
 * Creates a texture stamped polyline with gradient background and adds it to the supplied map.
 *
 * @param map The map to add the polyline to.
 */
- (void)addGradientTextureStampedPolylineToMap:(GMSMapView *)map {
  GMSMutablePath *texturePath = [GMSMutablePath path];
  [texturePath addLatitude:kSeattleLatitudeDegrees - 0.012 longitude:kSeattleLongitudeDegrees];
  [texturePath addLatitude:kSeattleLatitudeDegrees - 0.012
                 longitude:kSeattleLongitudeDegrees - 0.008];

  UIImage *_Nonnull textureStamp = (UIImage *_Nonnull)[UIImage imageNamed:@"aeroplane"];

  GMSStrokeStyle *gradientStroke = [GMSStrokeStyle gradientFromColor:[UIColor magentaColor]
                                                             toColor:[UIColor greenColor]];
  gradientStroke.stampStyle = [GMSTextureStyle textureStyleWithImage:textureStamp];

  GMSPolyline *gradientTexturePolyline = [GMSPolyline polylineWithPath:texturePath];
  gradientTexturePolyline.strokeWidth = kStrokeWidth * 1.5;
  gradientTexturePolyline.spans = @[ [GMSStyleSpan spanWithStyle:gradientStroke] ];
  gradientTexturePolyline.zIndex = 1;
  gradientTexturePolyline.map = map;
}

/**
 * Creates a sprite stamped polyline, using walking dots as the sprite, to the supplied map.
 *
 * @param map The map to add the polyline to.
 */
- (void)addSpriteWalkingDotStampedPolylineToMap:(GMSMapView *)map {
  GMSPath *path = [GMSPath pathFromEncodedPath:kEncodedPathForWalkingDirections];

  UIImage *_Nonnull stamp = (UIImage *_Nonnull)[UIImage imageNamed:@"walking_dot.png"];
  GMSStrokeStyle *stroke = [GMSStrokeStyle solidColor:[UIColor redColor]];
  stroke.stampStyle = [GMSSpriteStyle spriteStyleWithImage:stamp];
  GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
  polyline.map = map;
  polyline.strokeWidth = kStrokeWidth;
  polyline.spans = @[ [GMSStyleSpan spanWithStyle:stroke] ];
}

@end

NS_ASSUME_NONNULL_END
