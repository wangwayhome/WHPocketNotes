//
//  ViewController.m
//  PocketNotes
//
//  Created by weihong wang on 2025/12/5.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import "NoteManager.h"

@interface ViewController () <UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Pocket Notes";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // 创建文本框
    self.textView = [[UITextView alloc] init];
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.delegate = self;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.contentInset = UIEdgeInsetsMake(8, 4, 8, 4);
    
    if (self.note && self.note.text.length > 0) {
        self.textView.text = self.note.text;
        self.textView.textColor = [UIColor labelColor];
    } else {
        self.textView.text = @"Write down today's thoughts, memos, or inspirations here...";
        self.textView.textColor = [UIColor secondaryLabelColor];
    }
    
    [self.view addSubview:self.textView];
    
    // 使用 Masonry 约束，避免被刘海遮挡
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-8);
        } else {
            make.top.equalTo(self.mas_topLayoutGuideBottom).offset(8);
            make.bottom.equalTo(self.mas_bottomLayoutGuideTop).offset(-8);
        }
        make.left.equalTo(self.view.mas_left).offset(12);
        make.right.equalTo(self.view.mas_right).offset(-12);
    }];
    
    // 右上角添加“保存”按钮
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"SAVE"
                                                                  style:UIBarButtonItemStyleDone
                                                                 target:self
                                                                 action:@selector(saveButtonTapped)];
    self.navigationItem.rightBarButtonItem = saveItem;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (self.textView.textColor == [UIColor secondaryLabelColor]) {
        self.textView.text = @"";
        self.textView.textColor = [UIColor labelColor];
    }
}

// 点击保存按钮
- (void)saveButtonTapped {
    if (!self.note) {
        self.note = [[Note alloc] init];
    }
    self.note.text = self.textView.text;
    self.note.lastModified = [NSDate date];
    [[NoteManager sharedManager] saveNote:self.note];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
