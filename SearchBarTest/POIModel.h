//
//  POIModel.h
//  SearchBarTest
//
//  Created by kangda on 15/12/21.
//  Copyright © 2015年 kangda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface POIModel : NSObject
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *addressdetail;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longtitude;

@end
