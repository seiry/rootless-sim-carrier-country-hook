#import "TweakCommon.h"
#import <objc/runtime.h>

@implementation UIViewController (DownloadHelpers)

@dynamic suspenseTimer;
@dynamic previewItemURL;

- (AWEAwemeModel *)currentModel {
    return nil;
}

- (UIView *)findSubviewOfClass:(Class)cls inView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:cls]) {
            return subview;
        }
        UIView *result = [self findSubviewOfClass:cls inView:subview];
        if (result) {
            return result;
        }
    }
    return nil;
}

- (UIView *)findStackViewContainingRightInteractionArea:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([NSStringFromClass([subview class]) isEqualToString:@"TTKFeedInteractionStackView"]) {
            if ([self hasSubviewOfClass:NSClassFromString(@"TTKRightInteractionAreaBackgroundView") inView:subview]) {
                return subview;
            }
        }
        UIView *result = [self findStackViewContainingRightInteractionArea:subview];
        if (result) {
            return result;
        }
    }
    return nil;
}

- (BOOL)hasSubviewOfClass:(Class)cls inView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:cls]) {
            return YES;
        }
        if ([self hasSubviewOfClass:cls inView:subview]) {
            return YES;
        }
    }
    return NO;
}

- (void)viewDidAppearCommon:(BOOL)animated forViewController:(UIViewController *)viewController {
    // Check if we've already added the button
    if (objc_getAssociatedObject(viewController, @"kDownloadButtonKey")) {
        return;
    }

    // Find the TTKFeedInteractionMainView
    UIView *mainView = [self findSubviewOfClass:NSClassFromString(@"TTKFeedInteractionMainView") inView:viewController.view];
    if (!mainView) {
        NSLog(@"[TitCock] Couldn't find TTKFeedInteractionMainView");
        return;
    }

    // Find the correct TTKFeedInteractionStackView (the one containing TTKRightInteractionAreaBackgroundView)
    UIView *stackView = [self findStackViewContainingRightInteractionArea:mainView];
    if (!stackView) {
        NSLog(@"[TitCock] Couldn't find the correct TTKFeedInteractionStackView");
        return;
    }

    // Create and configure the download button container
    UIView *buttonContainer = [[UIView alloc] init];
    buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;

    // Create and configure the download button
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    downloadButton.translatesAutoresizingMaskIntoConstraints = NO;

    // Use a filled icon and make it larger
    UIImage *downloadImage = [[UIImage systemImageNamed:@"square.and.arrow.down.fill"] imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightMedium]];
    [downloadButton setImage:downloadImage forState:UIControlStateNormal];
    downloadButton.tintColor = [UIColor whiteColor];
    downloadButton.alpha = 0.9;
    [downloadButton addTarget:viewController action:@selector(handleDownload:) forControlEvents:UIControlEventTouchUpInside];

    // Add long press handler
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:viewController action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    [downloadButton addGestureRecognizer:longPress];

    // Add subviews
    [buttonContainer addSubview:downloadButton];

    // Set up constraints
    [NSLayoutConstraint activateConstraints:@[
        // Container constraints
        [buttonContainer.widthAnchor constraintEqualToConstant:80],
        [buttonContainer.heightAnchor constraintEqualToConstant:65],

        // Button constraints (49x49.5 with 23pt offset from left, 0 from top)
        [downloadButton.widthAnchor constraintEqualToConstant:52],
        [downloadButton.heightAnchor constraintEqualToConstant:52],
        [downloadButton.topAnchor constraintEqualToAnchor:buttonContainer.topAnchor],
        [downloadButton.leadingAnchor constraintEqualToAnchor:buttonContainer.leadingAnchor constant:23],
    ]];

    // mild drop shadow
    buttonContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    buttonContainer.layer.shadowOffset = CGSizeMake(0, 2);
    buttonContainer.layer.shadowRadius = 1;
    buttonContainer.layer.shadowOpacity = 0.25;

    // Add the container to the stack view after the first subview
    if ([stackView isKindOfClass:[UIStackView class]]) {
        UIStackView *uiStackView = (UIStackView *)stackView;
        if (uiStackView.arrangedSubviews.count > 0) {
            NSUInteger insertIndex = 1; // Index 1 is after the first subview
            [uiStackView insertArrangedSubview:buttonContainer atIndex:MIN(insertIndex, uiStackView.arrangedSubviews.count)];
        } else {
            [uiStackView addArrangedSubview:buttonContainer];
        }
    } else {
        // If it's not a UIStackView, we'll just add it as a subview
        if (stackView.subviews.count > 0) {
            [stackView insertSubview:buttonContainer atIndex:1];
        } else {
            [stackView addSubview:buttonContainer];
        }

        // You might need to adjust these constraints based on the actual layout
        [NSLayoutConstraint activateConstraints:@[
            [buttonContainer.topAnchor constraintEqualToAnchor:stackView.topAnchor],
            [buttonContainer.trailingAnchor constraintEqualToAnchor:stackView.trailingAnchor],
        ]];
    }

    // Store the button as an associated object
    objc_setAssociatedObject(viewController, @"kDownloadButtonKey", downloadButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)handleDownload:(UIButton *)sender {
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [generator impactOccurred];

    AWEAwemeModel *model = [self currentModel];

    if (model.photoAlbum != nil) {
        // Download every photo in the slideshow
        for (AWEPhotoAlbumPhoto *imageModel in model.photoAlbum.photos) {
            NSURL *imageURL = [NSURL URLWithString:imageModel.originPhotoURL.originURLList.firstObject];
            if (!imageURL) {
                NSLog(@"[TitCock] No image URL found");
                continue;
            }

            [self downloadFileFromURL:imageURL isVideo:NO sender:sender];
        }
    } else {
        // Download video
        NSString *videoURLString = ((AWEVideoBSModel *)model.video.bitrateModels.firstObject).playAddr.originURLList.firstObject;
        if (!videoURLString) {
            videoURLString = model.video.h264URL.originURLList.firstObject;
        }
        if (!videoURLString) {
            NSLog(@"[TitCock] No video URL found");
            return;
        }

        NSURL *videoURL = [NSURL URLWithString:videoURLString];
        [self downloadFileFromURL:videoURL isVideo:YES sender:sender];
    }
}

- (void)downloadFileFromURL:(NSURL *)url isVideo:(BOOL)isVideo sender:(UIButton *)sender {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 30.0;
    configuration.timeoutIntervalForResource = 60.0;
    configuration.networkServiceType = NSURLNetworkServiceTypeVideo;
    configuration.allowsExpensiveNetworkAccess = YES;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];

    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url];
    [downloadTask resume];

    [self startDownloadAnimation:sender];

    // Store the download task, sender button, and isVideo flag for later use
    objc_setAssociatedObject(self, @selector(currentDownloadTask), downloadTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(currentDownloadButton), sender, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(currentDownloadIsVideo), @(isVideo), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSNumber *isVideo = objc_getAssociatedObject(self, @selector(currentDownloadIsVideo));
    NSString *fileExtension = [isVideo boolValue] ? @"mp4" : @"jpg";
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.%@", (long)[NSDate date].timeIntervalSince1970, fileExtension]];
    NSURL *destinationURL = [NSURL fileURLWithPath:filePath];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager moveItemAtURL:location toURL:destinationURL error:nil];

    if ([isVideo boolValue]) {
        [self saveVideoToPhotos:destinationURL];
    } else {
        [self saveImageToPhotos:destinationURL];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([fileManager fileExistsAtPath:filePath]) {
            [fileManager removeItemAtPath:filePath error:nil];
        }
    });

    [self stopDownloadAnimation:objc_getAssociatedObject(self, @selector(currentDownloadButton))];

    // Show snackbar message
    NSString *message = [isVideo boolValue] ? @"Video saved to Photos" : @"Image saved to Photos";
    [self showSnackbarWithMessage:message];
}

- (void)showSnackbarWithMessage:(NSString *)message {
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    UIView *snackbar = [[UIView alloc] initWithFrame:CGRectMake(0, window.frame.size.height - 83, window.frame.size.width, 50)];
    snackbar.backgroundColor = [UIColor blackColor];
    snackbar.alpha = 0.0;

    UILabel *label = [[UILabel alloc] initWithFrame:snackbar.bounds];
    label.text = message;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;

    [snackbar addSubview:label];
    [window addSubview:snackbar];

    // Animate snackbar
    [UIView animateWithDuration:0.1 animations:^{
        snackbar.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            snackbar.alpha = 0.0;
        } completion:^(BOOL finished) {
            [snackbar removeFromSuperview];
        }];
    }];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    [self updateDownloadProgress:progress];
}

- (void)updateDownloadProgress:(float)progress {
    UIButton *button = objc_getAssociatedObject(self, @selector(currentDownloadButton));
    CAShapeLayer *progressLayer = objc_getAssociatedObject(button, @selector(progressLayer));

    if (!progressLayer) {
        progressLayer = [CAShapeLayer layer];
        progressLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(button.bounds.size.width / 2, button.bounds.size.height / 2)
                                                            radius:button.bounds.size.width / 2
                                                        startAngle:-M_PI_2
                                                          endAngle:3 * M_PI_2
                                                         clockwise:YES].CGPath;
        progressLayer.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
        progressLayer.fillColor = [UIColor clearColor].CGColor;
        progressLayer.lineWidth = 4.0;
        progressLayer.strokeEnd = 0.0;
        [button.layer addSublayer:progressLayer];

        objc_setAssociatedObject(button, @selector(progressLayer), progressLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    progressLayer.strokeEnd = progress;

    static UIImpactFeedbackGenerator *generator = nil;
    if (!generator) {
        generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
    }

    // Update haptic feedback based on progress
    NSNumber *lastProgressForHapticObj = objc_getAssociatedObject(self, @selector(lastProgressForHaptic));
    CGFloat lastProgressForHaptic = lastProgressForHapticObj ? [lastProgressForHapticObj floatValue] : 0;

    if (progress - lastProgressForHaptic >= 0.1) { // Trigger haptic every 10% progress
        [generator impactOccurred];
        objc_setAssociatedObject(self, @selector(lastProgressForHaptic), @(progress), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)stopDownloadAnimation:(UIButton *)button {
    button.userInteractionEnabled = YES;
    button.alpha = 0.9;
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [generator impactOccurred];
    usleep(100000);
    [generator impactOccurred];

    CAShapeLayer *progressLayer = objc_getAssociatedObject(button, @selector(progressLayer));
    [progressLayer removeFromSuperlayer];
    objc_setAssociatedObject(button, @selector(progressLayer), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Reset the progress for haptic feedback purposes
    objc_setAssociatedObject(self, @selector(lastProgressForHaptic), @(0), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self startSuspenseHaptics];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopSuspenseHaptics];
            [self copyModelInfoToClipboard];
            [self showCopiedAlert];
        });
    }
}

- (void)startDownloadAnimation:(UIButton *)button {
    button.userInteractionEnabled = NO;
    button.alpha = 0.5;

    // Initialize the progress
    objc_setAssociatedObject(self, @selector(lastProgressForHaptic), @(0), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Remove any existing progress layer
    CAShapeLayer *existingProgressLayer = objc_getAssociatedObject(button, @selector(progressLayer));
    [existingProgressLayer removeFromSuperlayer];

    // Create a new progress layer
    CAShapeLayer *progressLayer = [CAShapeLayer layer];
    progressLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(button.bounds.size.width / 2, button.bounds.size.height / 2)
                                                        radius:button.bounds.size.width / 2
                                                    startAngle:-M_PI_2
                                                      endAngle:3 * M_PI_2
                                                     clockwise:YES].CGPath;
    progressLayer.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
    progressLayer.fillColor = [UIColor clearColor].CGColor;
    progressLayer.lineWidth = 4.0;
    progressLayer.strokeEnd = 0.0;
    [button.layer addSublayer:progressLayer];

    objc_setAssociatedObject(button, @selector(progressLayer), progressLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)startSuspenseHaptics {
    self.suspenseTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [generator impactOccurred];
    }];
}

- (void)stopSuspenseHaptics {
    [self.suspenseTimer invalidate];
    self.suspenseTimer = nil;
}

- (void)showErrorAlert {
    UINotificationFeedbackGenerator *generator = [[UINotificationFeedbackGenerator alloc] init];
    [generator notificationOccurred:UINotificationFeedbackTypeError];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Failed to download video" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)showQuickLookPreviewWithURL:(NSURL *)fileURL {
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    previewController.dataSource = self;
    self.previewItemURL = fileURL;
    [self presentViewController:previewController animated:YES completion:nil];
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return self.previewItemURL;
}

- (void)saveVideoToPhotos:(NSURL *)videoURL {
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoURL.path)) {
        UISaveVideoAtPathToSavedPhotosAlbum(videoURL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    } else {
        NSLog(@"[TitCock] Error: Video format is not compatible with saved photos album");
    }
}

- (void)saveImageToPhotos:(NSURL *)imageURL {
    UIImage *image = [UIImage imageWithContentsOfFile:imageURL.path];
    if (image) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    } else {
        NSLog(@"[TitCock] Error: Unable to create image from file");
    }
}

- (void)saveImagesToPhotos:(NSArray<NSURL *> *)imageURLs {
    for (NSURL *imageURL in imageURLs) {
        UIImage *image = [UIImage imageWithContentsOfFile:imageURL.path];
        if (image) {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)(imageURL));
        } else {
            NSLog(@"[TitCock] Error: Unable to create image from file: %@", imageURL);
        }
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSURL *imageURL = (__bridge NSURL *)contextInfo;
    if (error) {
        NSLog(@"[TitCock] Error saving image to Photos: %@", error);
    } else {
        NSLog(@"[TitCock] Image saved to Photos successfully: %@", imageURL);
    }
    
    // Delete the temporary file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *deleteError;
    [fileManager removeItemAtURL:imageURL error:&deleteError];
    if (deleteError) {
        NSLog(@"[TitCock] Error deleting temporary image file: %@", deleteError);
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"[TitCock] Error saving video to Photos: %@", error);
    } else {
        NSLog(@"[TitCock] Video saved to Photos successfully");
    }
}

- (void)copyModelInfoToClipboard {
    AWEAwemeModel *model = [self currentModel];
    NSError *error;
    NSDictionary *modelDict = [model dictionaryRepresentation];
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:modelDict options:NSJSONWritingPrettyPrinted error:&error];
    if (jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        UIPasteboard.generalPasteboard.string = jsonString;
    } else {
        NSLog(@"[TitCock] Error converting model to JSON: %@", error);
    }
}

- (void)showCopiedAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Copied" message:@"Video info copied to clipboard" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end