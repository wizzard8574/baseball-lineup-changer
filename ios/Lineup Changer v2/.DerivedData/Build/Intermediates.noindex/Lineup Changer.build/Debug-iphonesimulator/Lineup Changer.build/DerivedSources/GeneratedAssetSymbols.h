#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.rmj.coachai";

/// The "LaunchBackgroundBlack" asset catalog color resource.
static NSString * const ACColorNameLaunchBackgroundBlack AC_SWIFT_PRIVATE = @"LaunchBackgroundBlack";

/// The "BBallCourtView" asset catalog image resource.
static NSString * const ACImageNameBBallCourtView AC_SWIFT_PRIVATE = @"BBallCourtView";

/// The "Football_Field_View" asset catalog image resource.
static NSString * const ACImageNameFootballFieldView AC_SWIFT_PRIVATE = @"Football_Field_View";

/// The "HockeyRink_View" asset catalog image resource.
static NSString * const ACImageNameHockeyRinkView AC_SWIFT_PRIVATE = @"HockeyRink_View";

/// The "LCLogo" asset catalog image resource.
static NSString * const ACImageNameLCLogo AC_SWIFT_PRIVATE = @"LCLogo";

/// The "Lacross_Field_View" asset catalog image resource.
static NSString * const ACImageNameLacrossFieldView AC_SWIFT_PRIVATE = @"Lacross_Field_View";

/// The "LaunchScreen" asset catalog image resource.
static NSString * const ACImageNameLaunchScreen AC_SWIFT_PRIVATE = @"LaunchScreen";

/// The "Soccer_Field_View" asset catalog image resource.
static NSString * const ACImageNameSoccerFieldView AC_SWIFT_PRIVATE = @"Soccer_Field_View";

/// The "SplashScreen" asset catalog image resource.
static NSString * const ACImageNameSplashScreen AC_SWIFT_PRIVATE = @"SplashScreen";

/// The "Volleyball_Court_View" asset catalog image resource.
static NSString * const ACImageNameVolleyballCourtView AC_SWIFT_PRIVATE = @"Volleyball_Court_View";

/// The "baseball_field_clean" asset catalog image resource.
static NSString * const ACImageNameBaseballFieldClean AC_SWIFT_PRIVATE = @"baseball_field_clean";

#undef AC_SWIFT_PRIVATE
