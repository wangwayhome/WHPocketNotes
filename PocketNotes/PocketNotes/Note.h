#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Note : NSObject <NSCoding>

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSDate *lastModified;

@end

NS_ASSUME_NONNULL_END
