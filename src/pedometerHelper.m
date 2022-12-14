#import "pedometerHelper.h"

#import <CoreMotion/CoreMotion.h>


// Dart_Port dartPort

// Function that accepts a dart port, starts the pedometer and forwards the resulting data.
void startPedometer() 
{

  // Create a pedometer
  CMPedometer *pedometer = [[CMPedometer alloc] init];
  NSLog(@"Created pedometer");

  NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-86400];

  // Start the pedometer
  [pedometer startPedometerUpdatesFromDate:yesterday withHandler:^(CMPedometerData *pedometerData, NSError *error) {

    NSLog(@"data:%@, error:%@", pedometerData, error);

    // Forward the results to the dart port
    // Dart_PostCObject_DL(dartPort, dartPedometerData);
  }];
}

