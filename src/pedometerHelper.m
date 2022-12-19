#import "pedometerHelper.h"

#import <CoreMotion/CoreMotion.h>

// Need to import the dart headers to get the definitions Dart_CObject
#include "dart-sdk/include/dart_api_dl.h"


// Helper function that converts NSNumber to a Dart C Object integer
static Dart_CObject NSObjectToCObject(NSNumber* n) {
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = (int64_t) n;
  return cobj;
}

// Function that accepts a start date string, dart port, and starts the pedometer and forwards the resulting data.
void startPedometer(Dart_Port sendPort){
  // Create a pedometer
  static CMPedometer *pedometer;
  pedometer = [[CMPedometer alloc] init];
  NSLog(@"Created pedometer");

  NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-86400];

  // Start the pedometer
  [pedometer startPedometerUpdatesFromDate:yesterday withHandler:^(CMPedometerData *pedometerData, NSError *error) {
    if(error == nil){
      NSLog(@"data:%@", pedometerData.numberOfSteps);
      Dart_CObject steps = NSObjectToCObject(pedometerData.numberOfSteps);
      const bool success = Dart_PostCObject_DL(sendPort, &steps);
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

