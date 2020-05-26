#import "IndbluetoothPlugin.h"
#import <UIKit/UIKit.h>
#import <FitBleKit/FitBleKit.h>

@interface DeviceClass : NSObject

@property (strong,nonatomic) id bleDevice;                    // 设备类
@property (strong,nonatomic) NSString *deviceId;              // 设备ID
@property (strong,nonatomic) NSString *deviceName;            // 设备名称
@property (assign,nonatomic) DeviceBleStatus connectStatus;   // 设备连接状态
@property (assign,nonatomic) BOOL isAvailable;                // 设备可用
@property (strong,nonatomic) NSMutableDictionary *deviceInfo; // 设备信息

@end

@implementation DeviceClass

- (id)init
{
    self.bleDevice     = nil;
    self.deviceId      = [[NSString alloc] init];
    self.deviceName    = [[NSString alloc] init];
    self.connectStatus = DeviceBleClosed;
    self.isAvailable   = NO;
    self.deviceInfo    = [[NSMutableDictionary alloc] init];
    
    return self;
}

@end

@interface ShowTools : NSObject

// 获取连接状态
+ (NSString *)showDeviceStatus:(DeviceBleStatus)status;

// 字节最大值溢出处理
+ (float )byteOverflow:(float)value andBitNumber:(int)bitNumber;

@end

@implementation ShowTools


/********************************************************************************
 * 方法名称：showDeviceStatus
 * 功能描述：获取连接状态
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
+ (NSString *)showDeviceStatus:(DeviceBleStatus)status {
    switch (status) {
        case DeviceBleClosed:
            return @"Closed";
            break;
            
        case DeviceBleIsOpen:
            return @"BleIsOpen";
            break;
            
        case DeviceBleSearching:
            return @"Searching";
            break;
            
        case DeviceBleConnecting:
            return @"Connecting";
            break;
            
        case DeviceBleConnected:
            return @"Connected";
            break;
            
        case DeviceBleSynchronization:
            return @"Synchronization";
            break;
            
        case DeviceBleSyncOver:
            return @"SyncOver";
            break;
            
        case DeviceBleSyncFailed:
            return @"SyncFailed";
            break;
            
        case DeviceBleDisconnecting:
            return @"Disconnecting";
            break;
            
            case DeviceBleDisconneced:
            return @"Disconneced";
            break;
            
        case DeviceBleReconnect:
            return @"Reconnecting";
            break;
            
        default:
            return @"nil";
            break;
    }
}


/***************************************************************************
 * 方法名称：byteOverflow
 * 功能描述：字节最大值溢出处理
 * 输入参数：
 * 返回数据：
 ***************************************************************************/
+ (float )byteOverflow:(float)value andBitNumber:(int)bitNumber {
    float hiNum = 0;
    float resultNum = value;
    
    if (bitNumber == 4) {
        int tww = 255;
        hiNum = (tww<<24)+(tww<<16)+(tww<<8)+tww;
    }
    else if (bitNumber == 2) {
        hiNum = 65535;
    }
    
    if (value < 0) {
        resultNum = value+hiNum;
    }
    
    return resultNum;
}


@end

@interface ScanDelegate : NSObject<FBKApiScanDevicesDelegate>
@property (nonatomic, copy) void (^poweredOn)(BOOL poweredOn);
@property (nonatomic, copy) void (^deviceList)(NSArray* deviceList);

@end

@implementation ScanDelegate
/********************************************************************************
 * 方法名称：phoneBleStatus
 * 功能描述：手机蓝牙状态
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)phoneBleStatus:(BOOL)isPoweredOn {
    self.poweredOn(isPoweredOn);
}


/********************************************************************************
 * 方法名称：getDeviceList
 * 功能描述：获取蓝牙列表数据
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)getDeviceList:(NSArray *)deviceList {
    self.deviceList(deviceList);
}
@end

@interface StreamHandlerDelegate : NSObject<FlutterStreamHandler>

@property (nonatomic, strong) void (^sink)(FlutterEventSink sink);
@end

@implementation StreamHandlerDelegate

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.sink(nil);
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    self.sink(events);
    return nil;
}

@end

@implementation IndbluetoothPlugin
static NSString *pluginName = @"IndbluetoothPluginName";

static NSString *START_SCAN = @"startScan";
static NSString *STOP_SCAN = @"stopScan";
static NSString *START_READ = @"startRead";
static NSString *STOP_READ = @"stopRead";
static NSString *deviceListChannelName = @"deviceListChannelName";
static NSString *heartrateChannelName = @"heartrateChannelName";
static NSString *deviceStatusChannelName = @"deviceStatusChannelName";

FlutterEventSink deviceListSink;
FlutterEventSink heartrateSink;
FlutterEventSink deviceStatusSink;

NSObject<FlutterPluginRegistrar>* mRegistrar;

ScanDelegate *scanDelegate;
FBKApiScanDevices *m_scanBlue;
bool bluetoothOn = false;
NSInteger currentDeviceCount = 0;
DeviceClass *myBleDevice;
NSMutableArray *bluetoothBeans;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    mRegistrar = registrar;
  FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:pluginName binaryMessenger:[registrar messenger]];
  IndbluetoothPlugin* instance = [[IndbluetoothPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        bluetoothBeans = [NSMutableArray array];
        m_scanBlue = [[FBKApiScanDevices alloc] init];
        scanDelegate = [[ScanDelegate alloc] init];
        scanDelegate.poweredOn = ^(BOOL poweredOn) {
            bluetoothOn = poweredOn;
        };
        scanDelegate.deviceList = ^(NSArray* deviceList) {
            if (currentDeviceCount != deviceList.count) {
                [bluetoothBeans removeAllObjects];
                [bluetoothBeans addObjectsFromArray:deviceList];
                currentDeviceCount = deviceList.count;
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                for (int i = 0; i < currentDeviceCount; i++) {
                    CBPeripheral *nowPeripheral = [[deviceList objectAtIndex:i] objectForKey:@"peripheral"];
                    if (nowPeripheral.name.length > 0 && nowPeripheral.identifier.UUIDString.length > 0) {
                        [dic setValue:nowPeripheral.name forKey:@"name"];
                        [dic setValue:nowPeripheral.identifier.UUIDString forKey:@"address"];
                        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error: nil];
                        if (deviceListSink != nil) {
                            deviceListSink([[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
                        }
                    }
                }
            }
    
        };
        m_scanBlue.delegate = scanDelegate;
        
        [self initDeviceListDelegate];
        [self initDeviceStatusDelegate];
        [self initHeartrateDelegate];
        
        FBKApiArmBand *armBandApi = [[FBKApiArmBand alloc] init];
        armBandApi.delegate = self;
        armBandApi.dataSource = self;
        
        myBleDevice = [[DeviceClass alloc] init];
        myBleDevice.bleDevice = armBandApi;
        myBleDevice.deviceId = @"";
        myBleDevice.isAvailable = NO;
        myBleDevice.connectStatus = DeviceBleClosed;
    }
    return self;
}

- (void) initDeviceListDelegate {
    StreamHandlerDelegate *shd = [[StreamHandlerDelegate alloc] init];
    shd.sink = ^(FlutterEventSink sink) {
        deviceListSink = sink;
    };
    [[FlutterEventChannel eventChannelWithName:deviceListChannelName binaryMessenger: [mRegistrar messenger]] setStreamHandler: shd];
}

- (void) initDeviceStatusDelegate {
    StreamHandlerDelegate *shd = [[StreamHandlerDelegate alloc] init];
    shd.sink = ^(FlutterEventSink sink) {
        deviceStatusSink = sink;
    };
    [[FlutterEventChannel eventChannelWithName:deviceStatusChannelName binaryMessenger: [mRegistrar messenger]] setStreamHandler: shd];
}

- (void) initHeartrateDelegate {
    StreamHandlerDelegate *shd = [[StreamHandlerDelegate alloc] init];
    shd.sink = ^(FlutterEventSink sink) {
        heartrateSink = sink;
    };
    [[FlutterEventChannel eventChannelWithName:heartrateChannelName binaryMessenger: [mRegistrar messenger]] setStreamHandler: shd];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([START_SCAN isEqualToString:call.method]) {
      if (bluetoothOn) {
          [m_scanBlue startScanBleApi:nil isRealTimeDevice:NO withRssi:70];
      }
      result(START_SCAN);
  } else if ([STOP_SCAN isEqualToString:call.method]) {
      if (bluetoothOn) {
          currentDeviceCount = 0;
          [m_scanBlue stopScanBleApi];
      }
      result(STOP_SCAN);
  } else if ([START_READ isEqualToString:call.method]) {
      NSLog(@"start read in oc");
      [m_scanBlue stopScanBleApi];
      NSString *address = call.arguments;
      NSLog(@"arguments: %@start read in oc", address);
      myBleDevice.deviceId = address;
//      myBleDevice.deviceName = [[deviceIdArray objectAtIndex:i] objectForKey:@"deviceName"];
      if (myBleDevice.isAvailable) {
        FBKApiArmBand *armBandApi = myBleDevice.bleDevice;
        [armBandApi startConnectBleApi:myBleDevice.deviceId andIdType:DeviceIdUUID];
        NSLog(@"myBleDevice.deviceId %@",myBleDevice.deviceId);
      }
      result(START_READ);
  } else if ([STOP_READ isEqualToString:call.method]) {
      [m_scanBlue stopScanBleApi];
      FBKApiArmBand *armBandApi = myBleDevice.bleDevice;
      [armBandApi disconnectBleApi];
      result(STOP_READ);
  }
}

/********************************************************************************
 * 方法名称：bleConnectStatus
 * 功能描述：蓝牙连接状态
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)bleConnectStatus:(DeviceBleStatus)status andDevice:(id)bleDevice {
    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
    FBKApiArmBand *listApi = myBleDevice.bleDevice;
    if (armBandApi == listApi) {
        myBleDevice.connectStatus = status;
        if (status == DeviceBleClosed) {
            myBleDevice.isAvailable = NO;
            if (deviceStatusSink) {
                deviceStatusSink([NSNumber numberWithInt: 0]);
            }
        } else if (status == DeviceBleIsOpen) {
            myBleDevice.isAvailable = YES;
            if (deviceStatusSink) {
                deviceStatusSink([NSNumber numberWithInt: 1]);
            }
            if (myBleDevice.deviceId.length > 0) {
                [listApi startConnectBleApi:myBleDevice.deviceId andIdType:DeviceIdUUID];
            }
        }
    }
}

/********************************************************************************
 * 方法名称：armBandRealTimeHeartRate
 * 功能描述：实时心率
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)armBandRealTimeHeartRate:(NSDictionary *)HRInfo andDevice:(id)bleDevice {
    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
//    DeviceClass *myBleDevice = [m_deviceList objectAtIndex:m_chooseNumber];
    FBKApiArmBand *chooseApi = (FBKApiArmBand *)myBleDevice.bleDevice;
    if (armBandApi == chooseApi) {
        if (heartrateSink) {
            NSString *str = [HRInfo objectForKey:@"heartRate"];
            NSInteger value = [str integerValue];
            heartrateSink([NSNumber numberWithInteger: value]);
        }
    }
}

/********************************************************************************
 * 方法名称：bleConnectError
 * 功能描述：蓝牙连接错误信息
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)bleConnectError:(id)error andDevice:(id)bleDevice {
//    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
//    DeviceClass *myBleDevice = [m_deviceList objectAtIndex:m_chooseNumber];
//    FBKApiArmBand *chooseApi = (FBKApiArmBand *)myBleDevice.bleDevice;
//    if (armBandApi == chooseApi) {
//        m_content.text = [NSString stringWithFormat:@"Device ID: %@\nError: %@",armBandApi.deviceId,error];
//    }
}


/********************************************************************************
 * 方法名称：devicePower
 * 功能描述：电量
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)devicePower:(NSString *)power andDevice:(id)bleDevice {
//    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
//    DeviceClass *myBleDevice = [m_deviceList objectAtIndex:m_chooseNumber];
//    FBKApiArmBand *chooseApi = (FBKApiArmBand *)myBleDevice.bleDevice;
//    if (armBandApi == chooseApi) {
//        NSString *bai = @"%";
//        m_content.text = [NSString stringWithFormat:@"Device ID: %@\nPower: %@%@",armBandApi.deviceId,power,bai];
//    }
}


/********************************************************************************
 * 方法名称：deviceFirmware
 * 功能描述：固件版本号
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)deviceFirmware:(NSString *)version andDevice:(id)bleDevice {
//    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
//    DeviceClass *myBleDevice = [m_deviceList objectAtIndex:m_chooseNumber];
//    FBKApiArmBand *chooseApi = (FBKApiArmBand *)myBleDevice.bleDevice;
//    if (armBandApi == chooseApi) {
//        m_content.text = [NSString stringWithFormat:@"Device ID: %@\nFirmware version: %@",armBandApi.deviceId,version];
//    }
}


/********************************************************************************
 * 方法名称：deviceHardware
 * 功能描述：硬件版本号
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)deviceHardware:(NSString *)version andDevice:(id)bleDevice {
//    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
//    DeviceClass *myBleDevice = [m_deviceList objectAtIndex:m_chooseNumber];
//    FBKApiArmBand *chooseApi = (FBKApiArmBand *)myBleDevice.bleDevice;
//    if (armBandApi == chooseApi) {
//        m_content.text = [NSString stringWithFormat:@"Device ID: %@\nHardware version: %@",armBandApi.deviceId,version];
//    }
}


/********************************************************************************
 * 方法名称：deviceSoftware
 * 功能描述：软件版本号
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)deviceSoftware:(NSString *)version andDevice:(id)bleDevice {
//    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
//    DeviceClass *myBleDevice = [m_deviceList objectAtIndex:m_chooseNumber];
//    FBKApiArmBand *chooseApi = (FBKApiArmBand *)myBleDevice.bleDevice;
//    if (armBandApi == chooseApi) {
//        m_content.text = [NSString stringWithFormat:@"Device ID: %@\nSoftware version: %@",armBandApi.deviceId,version];
//    }
}


/********************************************************************************
 * 方法名称：armBandVersion
 * 功能描述：协议版本号
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)armBandVersion:(NSString *)version andDevice:(id)bleDevice {
//    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
//    DeviceClass *myBleDevice = [m_deviceList objectAtIndex:m_chooseNumber];
//    FBKApiArmBand *chooseApi = (FBKApiArmBand *)myBleDevice.bleDevice;
//    if (armBandApi == chooseApi) {
//        m_content.text = [NSString stringWithFormat:@"Device ID: %@\nProtocol version: %@",armBandApi.deviceId,version];
//    }
}

/********************************************************************************
 * 方法名称：armBandStepFrequency
 * 功能描述：实时步频
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)armBandStepFrequency:(NSDictionary *)frequencyDic andDevice:(id)bleDevice {
//    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
//    DeviceClass *myBleDevice = [m_deviceList objectAtIndex:m_chooseNumber];
//    FBKApiArmBand *chooseApi = (FBKApiArmBand *)myBleDevice.bleDevice;
//    if (armBandApi == chooseApi) {
//        m_frequencyLab.text = [NSString stringWithFormat:@"steps: %@   stepFrequency: %@",[frequencyDic objectForKey:@"stepNum"],[frequencyDic objectForKey:@"stepFrequency"]];
//    }
}


/********************************************************************************
 * 方法名称：armBandDetailData
 * 功能描述：大数据
 * 输入参数：
 * 返回数据：
 ********************************************************************************/
- (void)armBandDetailData:(NSDictionary *)dataDic andDevice:(id)bleDevice {
//    FBKApiArmBand *armBandApi = (FBKApiArmBand *)bleDevice;
//    DeviceClass *myBleDevice = [m_deviceList objectAtIndex:m_chooseNumber];
//    FBKApiArmBand *chooseApi = (FBKApiArmBand *)myBleDevice.bleDevice;
//    if (armBandApi == chooseApi) {
//        NSMutableDictionary *dataDictionary = [[NSMutableDictionary alloc] initWithDictionary:dataDic];
//        if (dataDic.allKeys.count > 0) {
//            NewBandListViewController *listView = [[NewBandListViewController alloc] init];
//            listView.dataDic = dataDictionary;
//            [self.navigationController pushViewController:listView animated:YES];
//        }
//    }
}

@end
