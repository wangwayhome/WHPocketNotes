#import "NoteManager.h"

@interface NoteManager ()

@property (nonatomic, strong) NSMutableArray<Note *> *notes;
@property (nonatomic, copy) NSString *filePath;

@end

@implementation NoteManager

+ (instancetype)sharedManager {
    static NoteManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _filePath = [docsPath stringByAppendingPathComponent:@"notes.dat"];
        NSData *data = [NSData dataWithContentsOfFile:_filePath];
        if (data) {
            _notes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        if (!_notes) {
            _notes = [NSMutableArray array];
        }
    }
    return self;
}

- (void)saveNote:(Note *)note {
    BOOL found = NO;
    for (int i = 0; i < self.notes.count; i++) {
        if ([self.notes[i].uuid isEqualToString:note.uuid]) {
            self.notes[i] = note;
            found = YES;
            break;
        }
    }
    if (!found) {
        [self.notes insertObject:note atIndex:0];
    }
    [self _save];
}

- (void)deleteNote:(Note *)note {
    for (int i = 0; i < self.notes.count; i++) {
        if ([self.notes[i].uuid isEqualToString:note.uuid]) {
            [self.notes removeObjectAtIndex:i];
            break;
        }
    }
    [self _save];
}

- (NSArray<Note *> *)allNotes {
    return [self.notes copy];
}

- (void)_save {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.notes];
    [data writeToFile:self.filePath atomically:YES];
}

@end
