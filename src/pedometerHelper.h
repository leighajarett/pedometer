#import <CoreMotion/CoreMotion.h>
#import <CoreMotion/CMPedometer.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSDate.h>

#include "dart-sdk/include/dart_api_dl.h"

void startPedometer(Dart_Port sendPort, CMPedometer* pedometer, NSDate* start, NSDate* end);
