/********************************************************************************
 * 版权所有：深圳市一非科技有限公司
 * 文件名称：FBKAnalyticalHubConfig.h
 * 内容摘要：hub配置数据解析
 * 编辑作者：彭于
 * 版本编号：1.0.1
 * 创建日期：2018年06月27日
 ********************************************************************************/

#import <Foundation/Foundation.h>

@interface FBKAnalyticalHubConfig : NSObject

// 上传HUB登录状态
- (NSDictionary *)loginStatus:(NSArray *)hexArray;

// 上传hub登录密码
- (NSDictionary *)loginPassword:(NSArray *)hexArray;

// 上传wifi工作模式
- (NSDictionary *)wifiWorkMode:(NSArray *)hexArray;

// 上传 WIFI STA 信息
- (NSDictionary *)wifiSTAInfo:(NSArray *)hexArray;

// 上传 wifi Socket 信息
- (NSDictionary *)wifiSocketInfo:(NSArray *)hexArray;

// 上传HUB内外网模式
- (NSDictionary *)netWorkMode:(NSArray *)hexArray;

// 上传HUB备注信息
- (NSDictionary *)hubRemarkInfo:(NSArray *)hexArray;

// 上传HUB IP
- (NSDictionary *)hubIpKey:(NSArray *)hexArray;

// 上传wifi列表
- (NSDictionary *)hubWifiList:(NSArray *)hexArray;

// 上传wifi状态
- (NSDictionary *)hubWifiStatus:(NSArray *)hexArray;

@end
