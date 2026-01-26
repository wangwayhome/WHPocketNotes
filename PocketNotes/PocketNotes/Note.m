#import "Note.h"

static const CGFloat kJPEGCompressionQuality = 0.8f;

@implementation Note

- (instancetype)init {
    self = [super init];
    if (self) {
        _uuid = [[NSUUID UUID] UUIDString];
        _text = @"";
        _lastModified = [NSDate date];
        _images = [NSMutableArray array];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeObject:self.lastModified forKey:@"lastModified"];
    
    // Encode images as NSData
    if (self.images.count > 0) {
        NSMutableArray *imageDataArray = [NSMutableArray array];
        for (UIImage *image in self.images) {
            NSData *imageData = UIImageJPEGRepresentation(image, kJPEGCompressionQuality);
            if (imageData) {
                [imageDataArray addObject:imageData];
            }
        }
        [coder encodeObject:imageDataArray forKey:@"imageDataArray"];
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _uuid = [coder decodeObjectForKey:@"uuid"];
        _text = [coder decodeObjectForKey:@"text"];
        _lastModified = [coder decodeObjectForKey:@"lastModified"];
        
        // Decode image data
        NSArray *imageDataArray = [coder decodeObjectForKey:@"imageDataArray"];
        _images = [NSMutableArray array];
        if (imageDataArray) {
            for (NSData *imageData in imageDataArray) {
                UIImage *image = [UIImage imageWithData:imageData];
                if (image) {
                    [_images addObject:image];
                }
            }
        }
    }
    return self;
}

@end
