#import "pedometerHelper.h"

#import <CoreMotion/CoreMotion.h>

// Function that creates a handler to translate the results into Dart integers (or streams?), forwards the results to the dart port and calls that method.
// Should forward a stream to dart port

// Dart_Port dartPort

// Function that accepts a CMPedometerHandler and a dart port and starts the pedometer.
void startPedometer() 
{
  // Create a pedometer
  CMPedometer *pedometer = [[CMPedometer alloc] init];

  // Handler to translate the results into Dart integers (or streams?)
  //   CMPedometerHandler handler =

  // Start the pedometer
  [pedometer startPedometerUpdatesFromDate:nil withHandler:^(CMPedometerData *pedometerData, NSError *error) {

    NSLog(@"Steps = %@", pedometerData.numberOfSteps);

    // Forward the results to the dart port
    // Dart_PostCObject_DL(dartPort, dartPedometerData);
  }];
}
