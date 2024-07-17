#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@interface AWEURLModel : NSObject
@property(retain, nonatomic) NSArray* originURLList;
@end

@interface AWELongVideoControlModel : NSObject
@property(nonatomic) BOOL allowDownload;
@property(nonatomic) NSInteger preventDownloadType;
@end

@interface AWEVideoBSModel : NSObject
@property(readonly, nonatomic) AWEURLModel* playAddr;
@property(readonly, nonatomic) NSNumber* bitrate;
@end

@interface AWEVideoModel : NSObject
@property(readonly, nonatomic) AWEURLModel* playURL;
@property(readonly, nonatomic) AWEURLModel* downloadURL;
@property(readonly, nonatomic) AWEURLModel* h264URL;
@property(readonly, nonatomic) AWEURLModel* h264DownloadURL;
@property(readonly, nonatomic) NSArray *bitrateModels;
@property(readonly, nonatomic) NSNumber *duration;
@end

@interface AWEPhotoAlbumPhoto : NSObject
@property(retain, nonatomic) AWEURLModel* originPhotoURL;
@end

@interface AWEPhotoAlbumModel : NSObject
@property(retain, nonatomic) NSArray* photos;
@end

@interface AWEAwemeModel : NSObject
@property(nonatomic) BOOL isAds;
@property(nonatomic) NSObject *liveStreamURL;
@property(nonatomic) BOOL preventDownload;
@property(nonatomic) BOOL allowDownloadWithoutWatermark;
@property(retain, nonatomic) AWEVideoModel* video;
@property(retain, nonatomic) AWEPhotoAlbumModel* photoAlbum;
@property(retain, nonatomic) AWELongVideoControlModel* videoControl;
@property(readonly, nonatomic) NSString *region;
- (NSDictionary *)dictionaryRepresentation;
@end

@interface UIViewController (DownloadHelpers) <QLPreviewControllerDataSource, NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSTimer *suspenseTimer;
@property (nonatomic, strong) NSURL *previewItemURL;
- (UIView *)findSubviewOfClass:(Class)cls inView:(UIView *)view;
- (UIView *)findStackViewContainingRightInteractionArea:(UIView *)view;
- (BOOL)hasSubviewOfClass:(Class)cls inView:(UIView *)view;
- (void)viewDidAppearCommon:(BOOL)animated forViewController:(UIViewController *)viewController;
- (void)handleDownload:(UIButton *)sender;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)startDownloadAnimation:(UIButton *)button;
- (void)startSuspenseHaptics;
- (void)stopSuspenseHaptics;
- (void)showErrorAlert;
- (void)showQuickLookPreviewWithURL:(NSURL *)fileURL;
- (void)saveVideoToPhotos:(NSURL *)videoURL;
- (void)copyModelInfoToClipboard;
- (void)showCopiedAlert;
- (void)updateDownloadProgress:(float)progress;
- (void)stopDownloadAnimation:(UIButton *)button;
@end