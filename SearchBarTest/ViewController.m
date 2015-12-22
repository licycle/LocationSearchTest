//
//  ViewController.m
//  SearchBarTest
//
//  Created by kangda on 15/12/15.
//  Copyright © 2015年 kangda. All rights reserved.
//

/**
 *  O2O地址选择器，可以定位附近地址，历史地址，以及搜索地址，UI可以自定义
 *  本项目为公司项目的一个小功能，待公司APP上线后，尽量将不涉及机密的控件开源
 *
 */

#import "ViewController.h"
#import "POIModel.h"
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <CoreLocation/CoreLocation.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UISearchResultsUpdating,UITextFieldDelegate,BMKGeoCodeSearchDelegate,BMKPoiSearchDelegate,BMKLocationServiceDelegate>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) UITextField *textfield;
@property (nonatomic, assign) BOOL isediting;           //用户是否在输入


@property (nonatomic, strong) BMKPoiSearch *searcher;   //POI 百度工具
@property (nonatomic, strong) BMKGeoCodeSearch *geosearcher;    //地址搜索 百度工具
@property (nonatomic, strong) BMKLocationService *locService;   //地址定位 百度工具
@property (nonatomic, strong) NSMutableArray *poiresult;        //存储poi搜索结果
@property (nonatomic, strong) NSMutableArray *nearbyresult;     //存储附近地址结果
@property (nonatomic, strong) NSMutableArray *historyresult;    //存储历史结果
@property (nonatomic, strong) POIModel  *usernowresult;        //存储用户当前位置
@property (nonatomic) CLLocationCoordinate2D userlocation;     //用户当前位置经纬度

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    属性初始化
    _userlocation=CLLocationCoordinate2DMake(39.970482, 116.362603);
    _usernowresult=[[POIModel alloc]init];
    _isediting=NO;
    _poiresult=[[NSMutableArray alloc]init];
    _historyresult=[[NSMutableArray alloc]init];
    _nearbyresult=[[NSMutableArray alloc]init];
    _searcher =[[BMKPoiSearch alloc]init];
    _searcher.delegate = self;

    UIView *bg=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
    [bg setBackgroundColor:[UIColor greenColor]];
    _textfield=[[UITextField alloc]initWithFrame:CGRectMake(20, 10, self.view.frame.size.width-40, 20)];
    [bg addSubview:_textfield];
    _textfield.delegate=self;
    
    _tableview=[[UITableView alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height-20) style:UITableViewStyleGrouped];
    _tableview.tableHeaderView=bg;
    _tableview.tableFooterView=[[UIView alloc]initWithFrame:CGRectZero];
    _tableview.delegate=self;
    _tableview.dataSource=self;
    [self.view addSubview:_tableview];

//    定位功能开启
    _locService = [[BMKLocationService alloc]init];
    _locService.delegate = self;
    //启动LocationService
    [_locService startUserLocationService];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"cell"];
    
    POIModel *tempmodel=[[POIModel alloc]init];
    
    if (!_isediting) {
        switch (indexPath.section) {
            case 0:
                tempmodel=_usernowresult;
                break;
                
            case 2:
                if([_historyresult count]>0){
                    tempmodel=[_historyresult objectAtIndex:indexPath.row];
                }
                break;
                
            default:
                tempmodel=[_poiresult objectAtIndex:indexPath.row];
                break;
        }
    }
    else{
        switch (indexPath.section) {
            case 0:
                tempmodel=_usernowresult;
                break;
                
            default:
                tempmodel=[_poiresult objectAtIndex:indexPath.row];
                break;
        }
    }
    
    cell.textLabel.text=tempmodel.address;
    cell.detailTextLabel.text=tempmodel.addressdetail;
    
    return cell;
    
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(!_isediting)return 3;
    else return 2;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    UILabel *title=[[UILabel alloc]initWithFrame:CGRectMake(10, 10, 200, 30)];
    
    switch (section) {
        case 0:
            title.text=@"当前定位";
            break;
            
        case 1:
            title.text=@"搜索&附近地址";
            break;
            
        default:
            title.text=@"历史地址";
            break;
    }
    
    [header addSubview:title];
    [header setBackgroundColor:[UIColor whiteColor]];
    return  header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!_isediting) {
        switch (section) {
            case 0:
                return 1;
                break;
            
            case 2:
                return ([_historyresult count]>=3)?3:[_historyresult count];
                break;

            default:
                return [_poiresult count];
                break;
        }
    }
    else{
        switch (section) {
            case 0:
                return 1;
                break;
                
            default:
                return [_poiresult count];
                break;
        }
    }
}


#pragma mark-textfieddelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];    //主要是[receiver resignFirstResponder]在哪调用就能把receiver对应的键盘往下收
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    //发起检索
    BMKCitySearchOption *option = [[BMKCitySearchOption alloc]init];
    
    option.pageCapacity = 10;
    option.pageIndex=0;
    option.keyword = textField.text;
    option.city=_usernowresult.city;
    BOOL flag = [_searcher poiSearchInCity:option];
    if(flag)
    {
        NSLog(@"geo检索发送成功");
    }
    else
    {
        NSLog(@"geo检索发送失败");
    }
    
    return YES;
}


-(void)textFieldDidEndEditing:(UITextField *)textField
{
    _isediting=NO;
    
    //发起检索
    BMKCitySearchOption *option = [[BMKCitySearchOption alloc]init];
    
    option.pageCapacity = 10;
    option.pageIndex=0;
    option.keyword = textField.text;
    option.city=_usernowresult.city;
    BOOL flag = [_searcher poiSearchInCity:option];
    if(flag)
    {
        NSLog(@"geo检索发送成功");
    }
    else
    {
        NSLog(@"geo检索发送失败");
    }
    [_tableview reloadData];
    
    
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    _isediting=YES;
    
}

#pragma mark-baidumapdelegate

- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    NSLog(@"didUpdateUserLocation lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    
    [_locService stopUserLocationService];
    _userlocation=userLocation.location.coordinate;
    
    
     _geosearcher =[[BMKGeoCodeSearch alloc]init];
    _geosearcher.delegate=self;
    BMKReverseGeoCodeOption *reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeoCodeSearchOption.reverseGeoPoint = _userlocation;
    BOOL flag = [_geosearcher reverseGeoCode:reverseGeoCodeSearchOption];
    
    if(flag)
    {
      NSLog(@"反geo检索发送成功");
        
    }
    else
    {
      NSLog(@"反geo检索发送失败");
    }
}

//接收反向地理编码结果
-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:
(BMKReverseGeoCodeResult *)result
errorCode:(BMKSearchErrorCode)error{
  if (error == BMK_SEARCH_NO_ERROR) {
      _usernowresult.address=result.address;
      _usernowresult.city=result.addressDetail.city;
      _usernowresult.addressdetail=[NSString stringWithFormat:@"%@ %@ %@ %@ %@",result.addressDetail.province,result.addressDetail.city,result.addressDetail.district,result.addressDetail.streetName,result.addressDetail.streetNumber];
      _usernowresult.latitude=result.location.latitude;
      _usernowresult.longtitude=result.location.longitude;
      
      _poiresult=[self transformBaiduResult:result.poiList];
      
      [self.tableview reloadData];
      _geosearcher.delegate=nil;
  }
  else {
      NSLog(@"抱歉，未找到结果");
  }
}

- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)poiResultList errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        //在此处理正常结果
//        NSLog(@"%@",poiResultList.poiInfoList);
        _poiresult=[self transformBaiduResult:poiResultList.poiInfoList];
        [self.tableview reloadData];
        if(!_isediting)
        {
            if([_poiresult count]>0)
            {
                [_historyresult insertObject:[_poiresult firstObject] atIndex:0];
            }
        }
    
    }
    else if (error == BMK_SEARCH_AMBIGUOUS_KEYWORD){
        //当在设置城市未找到结果，但在其他城市找到结果时，回调建议检索城市列表
        // result.cityList;
        NSLog(@"起始点有歧义");
    } else {
        NSLog(@"抱歉，未找到结果");
    }
}


- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        //在此处理正常结果
        NSLog(@"%@",result);
    }
    else {
        NSLog(@"抱歉，未找到结果");
    }
}

#pragma mark-customdefined method
-(NSMutableArray*)transformBaiduResult:(NSArray*)array
{
    NSMutableArray *result=[[NSMutableArray alloc]init];
    for(BMKPoiInfo* obj in array)
    {
        POIModel *tempmodel=[[POIModel alloc]init];
        tempmodel.address=obj.name;
        tempmodel.addressdetail=[NSString stringWithFormat:@"%@ %@",obj.city,obj.address];
        tempmodel.latitude=obj.pt.latitude;
        tempmodel.longtitude=obj.pt.longitude;
        
        [result addObject:tempmodel];
    }
    return result;
}

@end
