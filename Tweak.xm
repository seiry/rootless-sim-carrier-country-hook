#import "Tweak.h"
#import "TweakCommon.h"
#import <objc/runtime.h>

// Region changing to the USA
%hook CTCarrier
- (NSString *)mobileCountryCode {
    return @"310";
}

- (NSString *)isoCountryCode {
    return @"US";
}

- (NSString *)mobileNetworkCode {
    return @"032";
}
%end

// No ads
%hook AWEAwemeModel
- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
    id orig = %orig;
    if (self.liveStreamURL != nil) {
        return nil;
    }
    return self.isAds ? nil : orig;
}

- (id)init {
    id orig = %orig;
    ((AWEAwemeModel *)orig).preventDownload = NO;
    ((AWEAwemeModel *)orig).allowDownloadWithoutWatermark = YES;
    if (self.liveStreamURL != nil) {
        return nil;
    }
    return self.isAds ? nil : orig;
}

- (BOOL)allowDownloadWithoutWatermark {
    return YES;
}
%end

%hook AWEFeedCellViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self viewDidAppearCommon:animated forViewController:self];
}

- (AWEAwemeModel *)currentModel {
    return self.model;
}
%end

%hook AWEAwemeDetailCellViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self viewDidAppearCommon:animated forViewController:self];
}

- (AWEAwemeModel *)currentModel {
    return self.model;
}
%end

%hook TTKPhotoAlbumFeedCellController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self viewDidAppearCommon:animated forViewController:self];
}

- (AWEAwemeModel *)currentModel {
    return self.model;
}
%end

// Settings hook
%hook TTKSettingsViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self tc_addTitCockSettings];
}

%new
- (void)tc_addTitCockSettings {
    if (objc_getAssociatedObject(self, @selector(tc_settingsButtonAdded))) {
        return;
    }
    
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [settingsButton setTitle:@"TitCock" forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(tc_showSettings) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.frame = CGRectMake(23, 30, 100, 50);
    [self.view.subviews.firstObject addSubview:settingsButton];
    
    objc_setAssociatedObject(self, @selector(tc_settingsButtonAdded), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (void)tc_showSettings {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TitCock"
                                                                   message:@"Settings options will be implemented here."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%end