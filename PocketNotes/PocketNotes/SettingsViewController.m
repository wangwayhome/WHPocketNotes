//
//  SettingsViewController.m
//  PocketNotes
//
//  Settings view for managing OpenAI API key
//

#import "SettingsViewController.h"
#import <Masonry/Masonry.h>

static NSString * const kOpenAIAPIKeyKeychainService = @"com.pocketnotes.openai";
static NSString * const kOpenAIAPIKeyKeychainAccount = @"apikey";

@interface SettingsViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITextField *apiKeyTextField;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *clearButton;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"AI Settings";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupUI];
    [self loadAPIKey];
}

- (void)setupUI {
    // Create scroll view
    self.scrollView = [[UIScrollView alloc] init];
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
    
    // Create content view
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"OpenAI API Key";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.titleLabel.textColor = [UIColor labelColor];
    [self.contentView addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(24);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    // Description label
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.text = @"Enter your OpenAI API key to enable AI features like text enhancement, summarization, and translation. Your API key is stored securely on your device.";
    self.descriptionLabel.font = [UIFont systemFontOfSize:14];
    self.descriptionLabel.textColor = [UIColor secondaryLabelColor];
    self.descriptionLabel.numberOfLines = 0;
    [self.contentView addSubview:self.descriptionLabel];
    
    [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    // API Key text field
    self.apiKeyTextField = [[UITextField alloc] init];
    self.apiKeyTextField.placeholder = @"sk-...";
    self.apiKeyTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.apiKeyTextField.font = [UIFont systemFontOfSize:16];
    self.apiKeyTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.apiKeyTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.apiKeyTextField.delegate = self;
    self.apiKeyTextField.secureTextEntry = YES;
    self.apiKeyTextField.accessibilityLabel = @"OpenAI API Key";
    self.apiKeyTextField.accessibilityHint = @"Enter your OpenAI API key that starts with sk-";
    [self.contentView addSubview:self.apiKeyTextField];
    
    [self.apiKeyTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descriptionLabel.mas_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@44);
    }];
    
    // Save button
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveButton setTitle:@"Save API Key" forState:UIControlStateNormal];
    self.saveButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.saveButton.backgroundColor = [UIColor systemBlueColor];
    self.saveButton.layer.cornerRadius = 8;
    [self.saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.saveButton];
    
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.apiKeyTextField.mas_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@50);
    }];
    
    // Clear button
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearButton setTitle:@"Clear API Key" forState:UIControlStateNormal];
    self.clearButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.clearButton setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    [self.clearButton addTarget:self action:@selector(clearButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.clearButton];
    
    [self.clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.saveButton.mas_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@44);
        make.bottom.equalTo(self.contentView).offset(-24);
    }];
}

#pragma mark - Keychain Methods

+ (BOOL)saveAPIKey:(NSString *)apiKey {
    if (!apiKey || apiKey.length == 0) {
        return NO;
    }
    
    NSData *apiKeyData = [apiKey dataUsingEncoding:NSUTF8StringEncoding];
    
    // First, try to delete existing key
    NSMutableDictionary *deleteQuery = [NSMutableDictionary dictionary];
    deleteQuery[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    deleteQuery[(__bridge id)kSecAttrService] = kOpenAIAPIKeyKeychainService;
    deleteQuery[(__bridge id)kSecAttrAccount] = kOpenAIAPIKeyKeychainAccount;
    SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
    
    // Add new key
    NSMutableDictionary *addQuery = [NSMutableDictionary dictionary];
    addQuery[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    addQuery[(__bridge id)kSecAttrService] = kOpenAIAPIKeyKeychainService;
    addQuery[(__bridge id)kSecAttrAccount] = kOpenAIAPIKeyKeychainAccount;
    addQuery[(__bridge id)kSecValueData] = apiKeyData;
    addQuery[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlocked;
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
    return status == errSecSuccess;
}

+ (NSString *)getAPIKey {
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrService] = kOpenAIAPIKeyKeychainService;
    query[(__bridge id)kSecAttrAccount] = kOpenAIAPIKeyKeychainAccount;
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status == errSecSuccess && result) {
        NSData *apiKeyData = (__bridge_transfer NSData *)result;
        return [[NSString alloc] initWithData:apiKeyData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

+ (BOOL)deleteAPIKey {
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrService] = kOpenAIAPIKeyKeychainService;
    query[(__bridge id)kSecAttrAccount] = kOpenAIAPIKeyKeychainAccount;
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    return status == errSecSuccess || status == errSecItemNotFound;
}

+ (BOOL)hasAPIKey {
    return [self getAPIKey] != nil;
}

#pragma mark - Actions

- (void)loadAPIKey {
    NSString *apiKey = [SettingsViewController getAPIKey];
    if (apiKey) {
        self.apiKeyTextField.text = apiKey;
    }
}

- (void)saveButtonTapped {
    NSString *apiKey = [self.apiKeyTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (!apiKey || apiKey.length == 0) {
        [self showAlertWithTitle:@"Error" message:@"Please enter an API key"];
        return;
    }
    
    if (![apiKey hasPrefix:@"sk-"]) {
        [self showAlertWithTitle:@"Warning" message:@"OpenAI API keys usually start with 'sk-'. Please verify your key is correct."];
    }
    
    if ([SettingsViewController saveAPIKey:apiKey]) {
        [self showAlertWithTitle:@"Success" message:@"API key saved successfully"];
    } else {
        [self showAlertWithTitle:@"Error" message:@"Failed to save API key"];
    }
}

- (void)clearButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear API Key"
                                                                   message:@"Are you sure you want to clear your API key? AI features will be disabled."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *clearAction = [UIAlertAction actionWithTitle:@"Clear"
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction * _Nonnull action) {
        if ([SettingsViewController deleteAPIKey]) {
            self.apiKeyTextField.text = @"";
            [self showAlertWithTitle:@"Success" message:@"API key cleared successfully"];
        } else {
            [self showAlertWithTitle:@"Error" message:@"Failed to clear API key"];
        }
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];
    
    [alert addAction:clearAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
