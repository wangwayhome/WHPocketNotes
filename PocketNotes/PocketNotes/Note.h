#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Note : NSObject <NSCoding>

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSDate *lastModified;
@property (nonatomic, strong, nullable) NSMutableArray<UIImage *> *images;

@end

NS_ASSUME_NONNULL_END
