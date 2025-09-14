#import <UIKit/UIKit.h>

struct ImFont;
@class MenuInteraction;

NS_ASSUME_NONNULL_BEGIN

@interface MenuLoad : NSObject

/// Shared singleton instance used throughout the menu system.
+ (instancetype)sharedInstance;

/// Hidden text field used for streamer mode
@property (nonatomic, strong, readonly) UITextField *hideRecordTextfield;

/// Global font reference for ImGui
@property (nonatomic, assign) ImFont *font;

/// Touch view forwarding events to ImGui
@property (nonatomic, strong, readonly) MenuInteraction *menuTouchView;

@end

@interface MenuInteraction : UIView
@end

NS_ASSUME_NONNULL_END
