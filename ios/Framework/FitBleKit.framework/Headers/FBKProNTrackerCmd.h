/********************************************************************************
 * 版权所有：深圳市一非科技有限公司
 * 文件名称：FBKProNTrackerCmd.m
 * 内容摘要：新手环蓝牙协议命令拼接
 * 编辑作者：彭于
 * 版本编号：1.0.1
 * 创建日期：2017年11月17日
 ********************************************************************************/

#import <Foundation/Foundation.h>
#import "FBKDeviceNewBand.h"

@protocol FBKProNTrackerCmdDelegate <NSObject>

// 传输写入的数据
- (void)sendBleCmdData:(NSData *)byteData;

@end


@interface FBKProNTrackerCmd : NSObject

// 版本号
@property (assign, nonatomic) int  m_softVersion;

// 回调协议
@property(assign,nonatomic)id <FBKProNTrackerCmdDelegate> delegate;

// 设置手环时间
- (void)setUTC;

// 设置个人基本信息
- (void)setUserInfoCmd:(FBKDeviceUserInfo *)userInfo;

// 设置个人睡眠信息
- (void)setSleepInfoCmd:(FBKDeviceSleepInfo *)sleepInfo;

// 设置个人喝水信息
- (void)setWaterInfoCmd:(FBKDeviceIntervalInfo *)waterInfo withSitSwitch:(NSString *)sitSwitch;

// 设置个人久坐信息
- (void)setSitInfoCmd:(FBKDeviceIntervalInfo *)sitInfo withWaterSwitch:(NSString *)waterSwitch;

// 设置个人通知信息
- (void)setNoticeInfoCmd:(FBKDeviceNoticeInfo *)noticeInfo;

// 设置个人闹钟信息
- (void)setAlarmInfoCmd:(NSArray *)alarmInfoArray;

// 设置单车参数命令
- (void)setBikeInfoCmd:(NSString *)whellDiameter;

// 设置心率最大值命令
- (void)setHeartRateMaxCmd:(NSString *)maxRate;

// 设置ANT等级命令
- (void)setANTInfoCmd:(NSString *)ANTLevel;

// 开启实时数据
- (void)openRealTimeStepsCmd:(NSString *)status;

// 开启拍照
- (void)openTakePhotoCmd:(NSString *)status;

// 开启心率模式
- (void)openHeartRateModeCmd:(NSString *)status;

// 设置进入配对模式
- (void)openANCSModeCmd:(NSString *)status;

// 获取设备支持信息
- (void)getDeviceSupportCmd;

// 获取上次同步的UTC
- (void)getBeforeUtcCmd;

// 获取所有历史数据
- (void)getTotalRecordCmd;

// 获取运动历史数据
- (void)getStepRecordCmd;

// 获取心率历史数据
- (void)getHeartRateRecordCmd;

// 获取踏频历史数据
- (void)getBikeRecordCmd;

// 获取训练历史数据
- (void)getTrainRecordCmd;

// 获取睡眠历史数据
- (void)getSleepRecordCmd;

// 获取每天步数总和历史数据
- (void)getEverydayRecordCmd;

// 秤命令
- (void)setWeightInfoCmd:(NSString *)mode andUnit:(NSString *)unitNum;

// 获取fit文件名列表
- (void)getFitNameList;

// 获取fit文件
- (void)getFitFile:(NSString *)fitFileName;

// 删除fit文件
- (void)deleteFitFile:(NSString *)fitFileName andDeleteType:(int)type;

// 设置码表时区
- (void)setFitTimeZone:(int)timeZone;

// 回复命令
- (void)getAckCmd:(NSString *)sortNumber;

// 发送命令成功
- (void)sendCmdSuseed:(NSString *)sortMark;


// HUB登录
- (void)hubLogin:(NSString *)hubPassword;

// 获取/设置登录密码
- (void)hubPassword:(NSDictionary *)hubPwDic isGetInfo:(BOOL)isGetMode;

// 获取/设置WiFi工作模式
- (void)hubWifiMode:(int)wifiMode isGetInfo:(BOOL)isGetMode;

// 获取/设置 WiFi STA
- (void)hubWifiSTA:(NSDictionary *)hubStaDic staMode:(int)modeNumber;

// 获取/设置Socket信息
- (void)hubSocketInfo:(NSDictionary *)hubSocketDic isGetInfo:(BOOL)isGetMode;

// 获取/设置HUB内外网模式
- (void)hubNetworkMode:(int)networkMode isGetInfo:(BOOL)isGetMode;

// 获取/设置HUB备注
- (void)hubRemark:(NSString *)markString isGetInfo:(BOOL)isGetMode;

// 获取HUB IP key
- (void)hubGetIpKey;

// HUB扫描WiFi
- (void)hubScanWifi;

// HUB复位重启
- (void)hubRestart;

// HUB恢复出厂设置
- (void)hubReset;

// 获取WiFi状态
- (void)hubGetWifiStatus;

@end
