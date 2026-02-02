#import <XCTest/XCTest.h>
#import "NoteManager.h"
#import "Note.h"

@interface NoteManagerTests : XCTestCase

@end

@implementation NoteManagerTests

- (NSString *)uniqueTempFilePath {
    NSString *tempDirectory = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"notes-%@.dat", [[NSUUID UUID] UUIDString]];
    return [tempDirectory stringByAppendingPathComponent:fileName];
}

- (NoteManager *)configuredManagerWithTemporaryStorage:(NSString *)filePath {
    NoteManager *manager = [NoteManager sharedManager];
    [manager setValue:filePath forKey:@"filePath"];
    [manager setValue:[NSMutableArray array] forKey:@"notes"];
    return manager;
}

- (void)testSaveNoteUpdatesExistingNoteWithoutReordering {
    NSString *filePath = [self uniqueTempFilePath];
    NoteManager *manager = [self configuredManagerWithTemporaryStorage:filePath];

    Note *firstNote = [[Note alloc] init];
    firstNote.text = @"First";

    Note *secondNote = [[Note alloc] init];
    secondNote.text = @"Second";

    [manager saveNote:firstNote];
    [manager saveNote:secondNote];

    Note *updatedFirstNote = [[Note alloc] init];
    updatedFirstNote.uuid = firstNote.uuid;
    updatedFirstNote.text = @"First Updated";

    [manager saveNote:updatedFirstNote];

    NSArray<Note *> *notes = [manager allNotes];
    XCTAssertEqual(notes.count, 2);
    XCTAssertEqualObjects(notes.firstObject.uuid, secondNote.uuid);
    XCTAssertEqualObjects(notes.lastObject.uuid, firstNote.uuid);
    XCTAssertEqualObjects(notes.lastObject.text, @"First Updated");
}

- (void)testDeleteNoteRemovesMatchingNote {
    NSString *filePath = [self uniqueTempFilePath];
    NoteManager *manager = [self configuredManagerWithTemporaryStorage:filePath];

    Note *firstNote = [[Note alloc] init];
    Note *secondNote = [[Note alloc] init];

    [manager saveNote:firstNote];
    [manager saveNote:secondNote];
    [manager deleteNote:firstNote];

    NSArray<Note *> *notes = [manager allNotes];
    XCTAssertEqual(notes.count, 1);
    XCTAssertEqualObjects(notes.firstObject.uuid, secondNote.uuid);
}

@end
