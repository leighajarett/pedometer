#import "pedometerHelper.h"

#import <CoreMotion/CoreMotion.h>

// Need to import the dart headers to get the definitions Dart_CObject
#include "dart-sdk/include/dart_api_dl.h"


// Helper function that takes a pointer to CMPedometer data and cinverts it to a Dart C Object
static Dart_CObject NSObjectToCObject(CMPedometerData* n) {
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = (int64_t) n;
  return cobj;
}

@implementation PedometerHelper

// Function that accepts a start date string, dart port, and starts the pedometer and forwards the resulting data.
+ (void) startPedometerWithPort: (Dart_Port) sendPort
                      pedometer: (CMPedometer*) pedometer
                          start: (NSDate*) start
                            end: (NSDate*) end {
  // Create a pedometer
//  static CMPedometer *pedometer;
//  pedometer = [[CMPedometer alloc] init];
  NSLog(@"Created pedometer");

//  NSDate* today = [NSDate date];
//  NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-86400];

  // Start the pedometer
  [pedometer queryPedometerDataFromDate:start toDate:end withHandler:^(CMPedometerData *pedometerData, NSError *error) {
    if(error == nil){
      NSLog(@"data:%@", pedometerData.numberOfSteps);
      NSLog(@"start:%@", pedometerData.startDate);
      NSLog(@"end:%@", pedometerData.endDate);
      Dart_CObject data = NSObjectToCObject(pedometerData);
      const bool success = Dart_PostCObject_DL(sendPort, &data);

//      disable ARC
//      increment to do manual reference count
//      then add dart line

// make sure that Liam's proposal

      NSLog(@"Finished sending");
//      NSLog(@"Value:%@",  steps.value.as_int64);
//      const bool success = Dart_PostCObject_DL(sendPort, &steps);
//      NSAssert(success, @"Dart_PostCObject_DL failed.");
    }
    else{
      NSLog(@"Error:%@", error);
    }

//    NSTimeInterval delayInSeconds = 120.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//      NSLog(@"Stop the pedometer");
//      [pedometer stopPedometerUpdates];
//    });


  }];
}

@end