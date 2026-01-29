//
//  SettingsViewController.h
//  PocketNotes
//
//  Settings view for managing OpenAI API key
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsViewController : UIViewController

// Public API for keychain operations
+ (BOOL)saveAPIKey:(NSString *)apiKey;
+ (NSString * _Nullable)getAPIKey;
+ (BOOL)deleteAPIKey;
+ (BOOL)hasAPIKey;

@end

NS_ASSUME_NONNULL_END
