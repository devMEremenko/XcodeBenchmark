/*
 * Copyright 2016 Google LLC. All rights reserved.
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

#import "GoogleMapsDemos/Samples/MapLayerViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@implementation MapLayerViewController {
  GMSMapView *_mapView;
  BOOL _rotating;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-37.81969
                                                          longitude:144.966085
                                                               zoom:4];
  _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  self.view = _mapView;

  GMSMapView *mapView = _mapView;
  dispatch_async(dispatch_get_main_queue(), ^{
    mapView.myLocationEnabled = YES;
  });

  UIBarButtonItem *myLocationButton =
      [[UIBarButtonItem alloc] initWithTitle:@"Fly to My Location"
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(didTapMyLocation)];
  self.navigationItem.rightBarButtonItem = myLocationButton;
}

- (void)didTapMyLocation {
  CLLocation *location = _mapView.myLocation;
  if (!location || !CLLocationCoordinate2DIsValid(location.coordinate)) {
    return;
  }
  GMSCameraPosition *camera =
      [[GMSCameraPosition alloc] initWithTarget:location.coordinate
                                           zoom:_mapView.camera.zoom
                                        bearing:0.0
                                   viewingAngle:_mapView.camera.viewingAngle];
  CAMediaTimingFunction *curve =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  // Animate to the marker
  [CATransaction begin];
  [CATransaction setAnimationDuration:2.0f];  // 2 second animation
  [CATransaction setAnimationTimingFunction:curve];
  [CATransaction setCompletionBlock:^{
    if (_rotating) {  // Animation was interrupted by orientation change.
      [CATransaction
          setDisableActions:true];  // Disable animation to avoid interruption from rotation.
      [_mapView animateToCameraPosition:camera];
    }
  }];

  [_mapView animateToCameraPosition:camera];
  [CATransaction commit];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  _rotating = true;
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [coordinator
      animateAlongsideTransition:nil
                      completion:^(
                          id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
                        _rotating = false;
                      }];
}

@end
