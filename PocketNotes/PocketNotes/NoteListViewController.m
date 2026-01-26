#import "NoteListViewController.h"
#import "ViewController.h"
#import "NoteManager.h"
#import "Note.h"

@interface NoteListViewController () <UISearchResultsUpdating>

@property (nonatomic, strong) NSArray<Note *> *notes;
@property (nonatomic, strong) NSMutableArray<Note *> *filteredNotes;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation NoteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Pocket Notes";
    
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewNote)];
    self.navigationItem.rightBarButtonItem = addItem;
    
    self.filteredNotes = [NSMutableArray array];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.navigationItem.searchController = self.searchController;
    self.definesPresentationContext = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadNotes];
}

- (void)loadNotes {
    self.notes = [[NoteManager sharedManager] allNotes];
    [self.tableView reloadData];
}

- (void)addNewNote {
    ViewController *vc = [[ViewController alloc] init];
    vc.note = [[Note alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (BOOL)isSearching {
    return self.searchController.isActive && self.searchController.searchBar.text.length > 0;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    [self.filteredNotes removeAllObjects];
    
    if (searchText.length > 0) {
        for (Note *note in self.notes) {
            if ([note.text.lowercaseString containsString:searchText.lowercaseString]) {
                [self.filteredNotes addObject:note];
            }
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self isSearching] ? self.filteredNotes.count : self.notes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"NoteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    Note *note = [self isSearching] ? self.filteredNotes[indexPath.row] : self.notes[indexPath.row];
    
    // Show first line of text or "New Note"
    NSString *displayText = note.text.length > 0 ? [note.text componentsSeparatedByString:@"\n"].firstObject : @"New Note";
    
    // Add image indicator if note has images
    if (note.images.count > 0) {
        displayText = [NSString stringWithFormat:@"📷 %@", displayText];
    }
    
    cell.textLabel.text = displayText;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    cell.detailTextLabel.text = [formatter stringFromDate:note.lastModified];
    
    // Show thumbnail if note has images
    if (note.images.count > 0) {
        UIImage *thumbnail = note.images.firstObject;
        CGSize thumbnailSize = CGSizeMake(60, 60);
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, NO, 0.0);
        [thumbnail drawInRect:CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height)];
        UIImage *resizedThumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        cell.imageView.image = resizedThumbnail;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.imageView.layer.cornerRadius = 8;
        cell.imageView.layer.masksToBounds = YES;
    } else {
        cell.imageView.image = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.searchController.active = NO;
    ViewController *vc = [[ViewController alloc] init];
    vc.note = [self isSearching] ? self.filteredNotes[indexPath.row] : self.notes[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Note *noteToDelete;
        if ([self isSearching]) {
            noteToDelete = self.filteredNotes[indexPath.row];
            [self.filteredNotes removeObjectAtIndex:indexPath.row];
        } else {
            noteToDelete = self.notes[indexPath.row];
        }
        
        // Delete from data source
        [[NoteManager sharedManager] deleteNote:noteToDelete];
        
        // Also remove from the main notes array if it exists there
        NSMutableArray *mutableNotes = [self.notes mutableCopy];
        [mutableNotes removeObject:noteToDelete];
        self.notes = [mutableNotes copy];
        
        // Delete the row from the table view
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
