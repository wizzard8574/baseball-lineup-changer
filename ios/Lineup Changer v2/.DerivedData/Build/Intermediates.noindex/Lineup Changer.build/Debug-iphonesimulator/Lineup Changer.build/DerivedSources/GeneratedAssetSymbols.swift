import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "LaunchBackgroundBlack" asset catalog color resource.
    static let launchBackgroundBlack = DeveloperToolsSupport.ColorResource(name: "LaunchBackgroundBlack", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "BBallCourtView" asset catalog image resource.
    static let bBallCourtView = DeveloperToolsSupport.ImageResource(name: "BBallCourtView", bundle: resourceBundle)

    /// The "Football_Field_View" asset catalog image resource.
    static let footballFieldView = DeveloperToolsSupport.ImageResource(name: "Football_Field_View", bundle: resourceBundle)

    /// The "HockeyRink_View" asset catalog image resource.
    static let hockeyRinkView = DeveloperToolsSupport.ImageResource(name: "HockeyRink_View", bundle: resourceBundle)

    /// The "LCLogo" asset catalog image resource.
    static let lcLogo = DeveloperToolsSupport.ImageResource(name: "LCLogo", bundle: resourceBundle)

    /// The "Lacross_Field_View" asset catalog image resource.
    static let lacrossFieldView = DeveloperToolsSupport.ImageResource(name: "Lacross_Field_View", bundle: resourceBundle)

    /// The "LaunchScreen" asset catalog image resource.
    static let launchScreen = DeveloperToolsSupport.ImageResource(name: "LaunchScreen", bundle: resourceBundle)

    /// The "Soccer_Field_View" asset catalog image resource.
    static let soccerFieldView = DeveloperToolsSupport.ImageResource(name: "Soccer_Field_View", bundle: resourceBundle)

    /// The "SplashScreen" asset catalog image resource.
    static let splashScreen = DeveloperToolsSupport.ImageResource(name: "SplashScreen", bundle: resourceBundle)

    /// The "Volleyball_Court_View" asset catalog image resource.
    static let volleyballCourtView = DeveloperToolsSupport.ImageResource(name: "Volleyball_Court_View", bundle: resourceBundle)

    /// The "baseball_field_clean" asset catalog image resource.
    static let baseballFieldClean = DeveloperToolsSupport.ImageResource(name: "baseball_field_clean", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "LaunchBackgroundBlack" asset catalog color.
    static var launchBackgroundBlack: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .launchBackgroundBlack)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "LaunchBackgroundBlack" asset catalog color.
    static var launchBackgroundBlack: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .launchBackgroundBlack)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "LaunchBackgroundBlack" asset catalog color.
    static var launchBackgroundBlack: SwiftUI.Color { .init(.launchBackgroundBlack) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "LaunchBackgroundBlack" asset catalog color.
    static var launchBackgroundBlack: SwiftUI.Color { .init(.launchBackgroundBlack) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "BBallCourtView" asset catalog image.
    static var bBallCourtView: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bBallCourtView)
#else
        .init()
#endif
    }

    /// The "Football_Field_View" asset catalog image.
    static var footballFieldView: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .footballFieldView)
#else
        .init()
#endif
    }

    /// The "HockeyRink_View" asset catalog image.
    static var hockeyRinkView: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hockeyRinkView)
#else
        .init()
#endif
    }

    /// The "LCLogo" asset catalog image.
    static var lcLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lcLogo)
#else
        .init()
#endif
    }

    /// The "Lacross_Field_View" asset catalog image.
    static var lacrossFieldView: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lacrossFieldView)
#else
        .init()
#endif
    }

    /// The "LaunchScreen" asset catalog image.
    static var launchScreen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .launchScreen)
#else
        .init()
#endif
    }

    /// The "Soccer_Field_View" asset catalog image.
    static var soccerFieldView: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .soccerFieldView)
#else
        .init()
#endif
    }

    /// The "SplashScreen" asset catalog image.
    static var splashScreen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .splashScreen)
#else
        .init()
#endif
    }

    /// The "Volleyball_Court_View" asset catalog image.
    static var volleyballCourtView: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volleyballCourtView)
#else
        .init()
#endif
    }

    /// The "baseball_field_clean" asset catalog image.
    static var baseballFieldClean: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .baseballFieldClean)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "BBallCourtView" asset catalog image.
    static var bBallCourtView: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bBallCourtView)
#else
        .init()
#endif
    }

    /// The "Football_Field_View" asset catalog image.
    static var footballFieldView: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .footballFieldView)
#else
        .init()
#endif
    }

    /// The "HockeyRink_View" asset catalog image.
    static var hockeyRinkView: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hockeyRinkView)
#else
        .init()
#endif
    }

    /// The "LCLogo" asset catalog image.
    static var lcLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lcLogo)
#else
        .init()
#endif
    }

    /// The "Lacross_Field_View" asset catalog image.
    static var lacrossFieldView: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lacrossFieldView)
#else
        .init()
#endif
    }

    /// The "LaunchScreen" asset catalog image.
    static var launchScreen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .launchScreen)
#else
        .init()
#endif
    }

    /// The "Soccer_Field_View" asset catalog image.
    static var soccerFieldView: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .soccerFieldView)
#else
        .init()
#endif
    }

    /// The "SplashScreen" asset catalog image.
    static var splashScreen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .splashScreen)
#else
        .init()
#endif
    }

    /// The "Volleyball_Court_View" asset catalog image.
    static var volleyballCourtView: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volleyballCourtView)
#else
        .init()
#endif
    }

    /// The "baseball_field_clean" asset catalog image.
    static var baseballFieldClean: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .baseballFieldClean)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

