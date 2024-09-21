#import <rootless.h>
#import <objc/runtime.h>
#import <CoreTelephony/CTCarrier.h>

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
