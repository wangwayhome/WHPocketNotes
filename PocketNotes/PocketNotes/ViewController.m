//
//  ViewController.m
//  PocketNotes
//
//  Created by weihong wang on 2025/12/5.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import "NoteManager.h"
#import "AIService.h"
#import "SettingsViewController.h"

static const CGFloat kImageContainerMargin = 24.0;
static const CGFloat kMaxImageHeight = 400.0;
static const NSInteger kFullScreenViewTag = 999;

@interface ViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStackView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

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
            make.edges.equalTo(self.view.mas_safeAreaLayoutGuide);
        } else {
            make.top.equalTo(self.mas_topLayoutGuideBottom);
            make.bottom.equalTo(self.mas_bottomLayoutGuideTop);
            make.left.right.equalTo(self.view);
        }
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
    
    // Add image button, AI button and save button
    UIBarButtonItem *addImageItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                   target:self
                                                                                   action:@selector(addImageButtonTapped)];
    addImageItem.accessibilityLabel = @"Add Image";
    
    UIBarButtonItem *aiItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"sparkles"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(aiButtonTapped)];
    aiItem.accessibilityLabel = @"AI Features";
    
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"SAVE"
                                                                  style:UIBarButtonItemStyleDone
                                                                 target:self
                                                                 action:@selector(saveButtonTapped)];
    self.navigationItem.rightBarButtonItems = @[saveItem, aiItem, addImageItem];
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
    CGFloat calculatedHeight = MIN(aspectRatio * (self.view.bounds.size.width - kImageContainerMargin), kMaxImageHeight);
    
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(calculatedHeight));
    }];
}

- (void)imageViewTapped:(UITapGestureRecognizer *)gesture {
    UIImageView *imageView = (UIImageView *)gesture.view;
    
    // Create full screen view
    UIView *fullScreenView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    fullScreenView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    fullScreenView.tag = kFullScreenViewTag;
    
    UIImageView *fullScreenImageView = [[UIImageView alloc] initWithImage:imageView.image];
    fullScreenImageView.contentMode = UIViewContentModeScaleAspectFit;
    fullScreenImageView.frame = fullScreenView.bounds;
    [fullScreenView addSubview:fullScreenImageView];
    
    // Add tap to dismiss
    UITapGestureRecognizer *tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissFullScreenImage:)];
    [fullScreenView addGestureRecognizer:tapToDismiss];
    
    // Add to window
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *w in windowScene.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
            }
            if (window) break;
        }
    } else {
        window = [UIApplication sharedApplication].keyWindow;
    }
    
    if (!window) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    
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

#pragma mark - AI Features

- (void)aiButtonTapped {
    if (![[AIService sharedService] isConfigured]) {
        [self showAINotConfiguredAlert];
        return;
    }
    
    if (self.textView.text.length == 0 || [self.textView.textColor isEqual:[UIColor secondaryLabelColor]]) {
        [self showAlertWithTitle:@"No Text" message:@"Please enter some text first to use AI features."];
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AI Features"
                                                                   message:@"Choose an AI action"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *enhanceAction = [UIAlertAction actionWithTitle:@"✨ Enhance Text"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        [self enhanceText];
    }];
    
    UIAlertAction *summarizeAction = [UIAlertAction actionWithTitle:@"📝 Summarize"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
        [self summarizeText];
    }];
    
    UIAlertAction *translateAction = [UIAlertAction actionWithTitle:@"🌍 Translate"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
        [self showTranslateOptions];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:enhanceAction];
    [alert addAction:summarizeAction];
    [alert addAction:translateAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAINotConfiguredAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AI Not Configured"
                                                                   message:@"Please configure your OpenAI API key in Settings to use AI features."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Go to Settings"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
        SettingsViewController *settingsVC = [[SettingsViewController alloc] init];
        [self.navigationController pushViewController:settingsVC animated:YES];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:settingsAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)enhanceText {
    [self showLoadingIndicator];
    
    __weak typeof(self) weakSelf = self;
    [[AIService sharedService] enhanceText:self.textView.text completion:^(NSString * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        [strongSelf hideLoadingIndicator];
        
        if (error) {
            [strongSelf showAlertWithTitle:@"Error" message:error.localizedDescription];
            return;
        }
        
        if (result) {
            [strongSelf showResultAlert:result withTitle:@"Enhanced Text"];
        }
    }];
}

- (void)summarizeText {
    [self showLoadingIndicator];
    
    __weak typeof(self) weakSelf = self;
    [[AIService sharedService] summarizeText:self.textView.text completion:^(NSString * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        [strongSelf hideLoadingIndicator];
        
        if (error) {
            [strongSelf showAlertWithTitle:@"Error" message:error.localizedDescription];
            return;
        }
        
        if (result) {
            [strongSelf showResultAlert:result withTitle:@"Summary"];
        }
    }];
}

- (void)showTranslateOptions {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Translate To"
                                                                   message:@"Select target language"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *languages = @[@"Chinese", @"English", @"Spanish", @"French", @"German", @"Japanese", @"Korean"];
    
    for (NSString *language in languages) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:language
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
            [self translateTextToLanguage:language];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)translateTextToLanguage:(NSString *)language {
    [self showLoadingIndicator];
    
    __weak typeof(self) weakSelf = self;
    [[AIService sharedService] translateText:self.textView.text toLanguage:language completion:^(NSString * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        [strongSelf hideLoadingIndicator];
        
        if (error) {
            [strongSelf showAlertWithTitle:@"Error" message:error.localizedDescription];
            return;
        }
        
        if (result) {
            [strongSelf showResultAlert:result withTitle:[NSString stringWithFormat:@"Translated to %@", language]];
        }
    }];
}

- (void)showResultAlert:(NSString *)result withTitle:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:result
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *replaceAction = [UIAlertAction actionWithTitle:@"Replace"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        self.textView.text = result;
        self.textView.textColor = [UIColor labelColor];
    }];
    
    UIAlertAction *appendAction = [UIAlertAction actionWithTitle:@"Append"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
        NSString *currentText = self.textView.text;
        if ([self.textView.textColor isEqual:[UIColor secondaryLabelColor]]) {
            currentText = @"";
        }
        self.textView.text = [NSString stringWithFormat:@"%@\n\n%@", currentText, result];
        self.textView.textColor = [UIColor labelColor];
    }];
    
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard.generalPasteboard.string = result;
        [self showAlertWithTitle:@"Copied" message:@"AI result copied to clipboard"];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:replaceAction];
    [alert addAction:appendAction];
    [alert addAction:copyAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showLoadingIndicator {
    if (!self.activityIndicator) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        self.activityIndicator.center = self.view.center;
        [self.view addSubview:self.activityIndicator];
    }
    
    [self.activityIndicator startAnimating];
    self.view.userInteractionEnabled = NO;
}

- (void)hideLoadingIndicator {
    [self.activityIndicator stopAnimating];
    self.view.userInteractionEnabled = YES;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
