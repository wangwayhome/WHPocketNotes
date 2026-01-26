#import "Note.h"

@implementation Note

- (instancetype)init {
    self = [super init];
    if (self) {
        _uuid = [[NSUUID UUID] UUIDString];
        _text = @"";
        _lastModified = [NSDate date];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeObject:self.lastModified forKey:@"lastModified"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _uuid = [coder decodeObjectForKey:@"uuid"];
        _text = [coder decodeObjectForKey:@"text"];
        _lastModified = [coder decodeObjectForKey:@"lastModified"];
    }
    return self;
}

@end
