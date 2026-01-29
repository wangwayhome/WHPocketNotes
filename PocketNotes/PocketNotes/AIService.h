//
//  AIService.h
//  PocketNotes
//
//  Service for OpenAI API integration
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AIServiceCompletionBlock)(NSString * _Nullable result, NSError * _Nullable error);

@interface AIService : NSObject

+ (instancetype)sharedService;

- (void)enhanceText:(NSString *)text completion:(AIServiceCompletionBlock)completion;
- (void)summarizeText:(NSString *)text completion:(AIServiceCompletionBlock)completion;
- (void)translateText:(NSString *)text toLanguage:(NSString *)language completion:(AIServiceCompletionBlock)completion;

- (BOOL)isConfigured;

@end

NS_ASSUME_NONNULL_END
