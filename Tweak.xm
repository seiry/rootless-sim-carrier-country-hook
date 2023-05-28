#include "Tweak.h"

%hook CTCarrier
// Thanks chenxk-j for this
// https://github.com/chenxk-j/hookTikTok/blob/master/hooktiktok/hooktiktok.xm#L23
// Region changing to USA
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
    return self.isAds ? nil : orig;
}

- (id)init {
    id orig = %orig;
    return self.isAds ? nil : orig;
}
%end