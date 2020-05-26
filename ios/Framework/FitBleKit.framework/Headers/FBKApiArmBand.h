/********************************************************************************
 * 版权所有：深圳市一非科技有限公司
 * 文件名称：FBKApiArmBand.h
 * 内容摘要：臂带API
 * 编辑作者：彭于
 * 版本编号：1.0.1
 * 创建日期：2018年03月26日
 ********************************************************************************/

#import "FBKApiBsaeMethod.h"

@protocol FBKApiArmBandDelegate <NSObject>

// 实时心率
- (void)armBandRealTimeHeartRate:(NSDictionary *)HRInfo andDevice:(id)bleDevice;

// 硬件版本号
- (void)armBandVersion:(NSString *)version andDevice:(id)bleDevice;

// 实时步频
- (void)armBandStepFrequency:(NSDictionary *)frequencyDic andDevice:(id)bleDevice;

// 大数据
- (void)armBandDetailData:(NSDictionary *)dataDic andDevice:(id)bleDevice;

@end


@interface FBKApiArmBand : FBKApiBsaeMethod

// 协议
@property(assign,nonatomic)id <FBKApiArmBandDelegate> delegate;

// 设置时间
- (void)setArmBandTime;

// 获取所有历史数据
- (void)getArmBandTotalHistory;

@end
