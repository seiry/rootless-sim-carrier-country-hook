#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TweakCommon.h"

@interface AWEFeedCellViewController : UIViewController
@property(nonatomic, strong) UIView *view;
@property(retain, nonatomic) AWEAwemeModel *model;
@end

@interface AWEAwemeDetailCellViewController : UIViewController
@property(nonatomic, strong) UIView *view;
@property(retain, nonatomic) AWEAwemeModel *model;
@end

@interface TTKPhotoAlbumFeedCellController : UIViewController
@property(nonatomic, strong) UIView *view;
@property(retain, nonatomic) AWEAwemeModel *model;
@end

@interface TTKSettingsViewController : UIViewController
@property(nonatomic, strong) UIView *view;
- (void)tc_addTitCockSettings;
- (void)tc_showSettings;
@end