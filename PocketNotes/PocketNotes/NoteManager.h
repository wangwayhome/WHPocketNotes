#import <Foundation/Foundation.h>
#import "Note.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoteManager : NSObject

+ (instancetype)sharedManager;

- (void)saveNote:(Note *)note;
- (void)deleteNote:(Note *)note;
- (NSArray<Note *> *)allNotes;

@end

NS_ASSUME_NONNULL_END
