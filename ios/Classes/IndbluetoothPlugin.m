#import "IndbluetoothPlugin.h"
#import <indbluetooth/indbluetooth-Swift.h>

@implementation IndbluetoothPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftIndbluetoothPlugin registerWithRegistrar:registrar];
}
@end
