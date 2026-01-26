//
//  ViewController.m
//  PocketNotes
//
//  Created by weihong wang on 2025/12/5.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import "NoteManager.h"

@interface ViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStackView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Pocket Notes";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Create scroll view
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.top.equalTo(self.mas_topLayoutGuideBottom);
            make.bottom.equalTo(self.mas_bottomLayoutGuideTop);
        }
        make.left.right.equalTo(self.view);
    }];
    
    // Create stack view for content
    self.contentStackView = [[UIStackView alloc] init];
    self.contentStackView.axis = UILayoutConstraintAxisVertical;
    self.contentStackView.spacing = 12;
    self.contentStackView.alignment = UIStackViewAlignmentFill;
    self.contentStackView.distribution = UIStackViewDistributionFill;
    [self.scrollView addSubview:self.contentStackView];
    
    [self.contentStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView).insets(UIEdgeInsetsMake(8, 12, 8, 12));
        make.width.equalTo(self.scrollView).offset(-24);
    }];
    
    // Create text view
    self.textView = [[UITextView alloc] init];
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.delegate = self;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.scrollEnabled = NO; // Let the outer scroll view handle scrolling
    
    if (self.note && self.note.text.length > 0) {
        self.textView.text = self.note.text;
        self.textView.textColor = [UIColor labelColor];
    } else {
        self.textView.text = @"Write down today's thoughts, memos, or inspirations here...";
        self.textView.textColor = [UIColor secondaryLabelColor];
    }
    
    [self.contentStackView addArrangedSubview:self.textView];
    
    // Set minimum height for text view
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.greaterThanOrEqualTo(@150);
    }];
    
    // Load existing images
    if (self.note && self.note.images.count > 0) {
        for (UIImage *image in self.note.images) {
            [self addImageViewToStack:image];
        }
    }
    
    // Add image button and save button
    UIBarButtonItem *addImageItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                   target:self
                                                                                   action:@selector(addImageButtonTapped)];
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"SAVE"
                                                                  style:UIBarButtonItemStyleDone
                                                                 target:self
                                                                 action:@selector(saveButtonTapped)];
    self.navigationItem.rightBarButtonItems = @[saveItem, addImageItem];
}

- (void)addImageViewToStack:(UIImage *)image {
    // Create a container view with rounded corners and shadow
    UIView *containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    containerView.layer.cornerRadius = 12;
    containerView.layer.masksToBounds = YES;
    
    // Create image view
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.userInteractionEnabled = YES;
    [containerView addSubview:imageView];
    
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(containerView);
    }];
    
    // Add tap gesture for full screen view
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
    [imageView addGestureRecognizer:tapGesture];
    
    // Add long press gesture for delete
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewLongPressed:)];
    [imageView addGestureRecognizer:longPressGesture];
    
    [self.contentStackView addArrangedSubview:containerView];
    
    // Calculate height based on aspect ratio
    CGFloat aspectRatio = image.size.height / image.size.width;
    CGFloat maxHeight = 400;
    CGFloat calculatedHeight = MIN(aspectRatio * (self.view.bounds.size.width - 24), maxHeight);
    
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(calculatedHeight));
    }];
}

- (void)imageViewTapped:(UITapGestureRecognizer *)gesture {
    UIImageView *imageView = (UIImageView *)gesture.view;
    
    // Create full screen view
    UIView *fullScreenView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    fullScreenView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    fullScreenView.tag = 999; // Tag for identification
    
    UIImageView *fullScreenImageView = [[UIImageView alloc] initWithImage:imageView.image];
    fullScreenImageView.contentMode = UIViewContentModeScaleAspectFit;
    fullScreenImageView.frame = fullScreenView.bounds;
    [fullScreenView addSubview:fullScreenImageView];
    
    // Add tap to dismiss
    UITapGestureRecognizer *tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissFullScreenImage:)];
    [fullScreenView addGestureRecognizer:tapToDismiss];
    
    // Add to window
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:fullScreenView];
    
    // Animate in
    fullScreenView.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        fullScreenView.alpha = 1;
    }];
}

- (void)dismissFullScreenImage:(UITapGestureRecognizer *)gesture {
    UIView *fullScreenView = gesture.view;
    [UIView animateWithDuration:0.3 animations:^{
        fullScreenView.alpha = 0;
    } completion:^(BOOL finished) {
        [fullScreenView removeFromSuperview];
    }];
}

- (void)imageViewLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIImageView *imageView = (UIImageView *)gesture.view;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"Delete this image?"
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction * _Nonnull action) {
            [self deleteImageView:imageView];
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        
        [alert addAction:deleteAction];
        [alert addAction:cancelAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)deleteImageView:(UIImageView *)imageView {
    UIView *containerView = imageView.superview;
    [self.contentStackView removeArrangedSubview:containerView];
    [containerView removeFromSuperview];
}

- (void)addImageButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Image"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Take Photo"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
        }];
        [alert addAction:cameraAction];
    }
    
    UIAlertAction *libraryAction = [UIAlertAction actionWithTitle:@"Choose from Library"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        [self showImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:libraryAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.delegate = self;
    picker.allowsEditing = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
    if (!selectedImage) {
        selectedImage = info[UIImagePickerControllerOriginalImage];
    }
    
    if (selectedImage) {
        [self addImageViewToStack:selectedImage];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (self.textView.textColor == [UIColor secondaryLabelColor]) {
        self.textView.text = @"";
        self.textView.textColor = [UIColor labelColor];
    }
}

- (void)saveButtonTapped {
    if (!self.note) {
        self.note = [[Note alloc] init];
    }
    self.note.text = self.textView.text;
    self.note.lastModified = [NSDate date];
    
    // Save images from stack view
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    for (UIView *arrangedView in self.contentStackView.arrangedSubviews) {
        if (arrangedView != self.textView) {
            // This is an image container
            for (UIView *subview in arrangedView.subviews) {
                if ([subview isKindOfClass:[UIImageView class]]) {
                    UIImageView *imageView = (UIImageView *)subview;
                    if (imageView.image) {
                        [images addObject:imageView.image];
                    }
                }
            }
        }
    }
    self.note.images = images;
    
    [[NoteManager sharedManager] saveNote:self.note];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
