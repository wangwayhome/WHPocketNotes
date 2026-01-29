//
//  AIService.m
//  PocketNotes
//
//  Service for OpenAI API integration
//

#import "AIService.h"
#import "SettingsViewController.h"

static NSString * const kOpenAIAPIURL = @"https://api.openai.com/v1/chat/completions";
static NSString * const kDefaultModel = @"gpt-3.5-turbo";
static NSTimeInterval const kRequestTimeout = 60.0;

@implementation AIService

static NSString *PNRedactedAPIKey(NSString *apiKey) {
    if (apiKey.length <= 8) {
        return @"[REDACTED]";
    }
    NSString *suffix = [apiKey substringFromIndex:apiKey.length - 4];
    return [NSString stringWithFormat:@"[REDACTED ...%@]", suffix];
}

+ (instancetype)sharedService {
    static AIService *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[self alloc] init];
    });
    return service;
}

- (BOOL)isConfigured {
    return [SettingsViewController hasAPIKey];
}

- (void)enhanceText:(NSString *)text completion:(AIServiceCompletionBlock)completion {
    NSString *prompt = [NSString stringWithFormat:@"Please improve and enhance the following text, making it more clear, concise, and well-structured. Keep the original meaning but improve the writing quality:\n\n%@", text];
    [self makeAPIRequestWithPrompt:prompt completion:completion];
}

- (void)summarizeText:(NSString *)text completion:(AIServiceCompletionBlock)completion {
    NSString *prompt = [NSString stringWithFormat:@"Please provide a concise summary of the following text:\n\n%@", text];
    [self makeAPIRequestWithPrompt:prompt completion:completion];
}

- (void)translateText:(NSString *)text toLanguage:(NSString *)language completion:(AIServiceCompletionBlock)completion {
    NSString *prompt = [NSString stringWithFormat:@"Please translate the following text to %@:\n\n%@", language, text];
    [self makeAPIRequestWithPrompt:prompt completion:completion];
}

- (void)makeAPIRequestWithPrompt:(NSString *)prompt completion:(AIServiceCompletionBlock)completion {
    NSString *apiKey = [SettingsViewController getAPIKey];
    
    if (!apiKey) {
        NSError *error = [NSError errorWithDomain:@"AIService" 
                                             code:1001 
                                         userInfo:@{NSLocalizedDescriptionKey: @"API key not configured"}];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, error);
        });
        return;
    }
    
    NSURL *url = [NSURL URLWithString:kOpenAIAPIURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = kRequestTimeout;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", apiKey] forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *message = @{
        @"role": @"user",
        @"content": prompt
    };
    
    NSDictionary *requestBody = @{
        @"model": kDefaultModel,
        @"messages": @[message],
        @"temperature": @0.7,
        @"max_tokens": @1000
    };
    
    NSError *jsonError;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestBody 
                                                          options:0 
                                                            error:&jsonError];
    
    if (jsonError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, jsonError);
        });
        return;
    }
    
    request.HTTPBody = requestData;
    
    NSString *requestBodyString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    NSLog(@"[AIService] Request URL: %@", kOpenAIAPIURL);
    NSLog(@"[AIService] Request Headers: Content-Type=application/json, Authorization=Bearer %@", PNRedactedAPIKey(apiKey));
    NSLog(@"[AIService] Request Body: %@", requestBodyString ?: @"<nil>");
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request 
                                                                 completionHandler:^(NSData * _Nullable data, 
                                                                                   NSURLResponse * _Nullable response, 
                                                                                   NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *responseBodyString = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
        NSLog(@"[AIService] Response Status: %ld", (long)httpResponse.statusCode);
        NSLog(@"[AIService] Response Body: %@", responseBodyString ?: @"<nil>");
        if (httpResponse.statusCode != 200) {
            NSString *errorMessage = [NSString stringWithFormat:@"API request failed with status code: %ld", (long)httpResponse.statusCode];
            
            // Try to parse error response
            if (data) {
                NSError *parseError;
                NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                if (!parseError && [errorDict isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *errorInfo = errorDict[@"error"];
                    if ([errorInfo isKindOfClass:[NSDictionary class]] && errorInfo[@"message"]) {
                        errorMessage = errorInfo[@"message"];
                    }
                }
            }
            
            NSError *apiError = [NSError errorWithDomain:@"AIService" 
                                                    code:httpResponse.statusCode 
                                                userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, apiError);
            });
            return;
        }
        
        if (!data) {
            NSError *noDataError = [NSError errorWithDomain:@"AIService" 
                                                       code:1002 
                                                   userInfo:@{NSLocalizedDescriptionKey: @"No data received"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, noDataError);
            });
            return;
        }
        
        NSError *parseError;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data 
                                                                     options:0 
                                                                       error:&parseError];
        
        if (parseError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, parseError);
            });
            return;
        }
        
        // Extract the response text
        NSArray *choices = responseDict[@"choices"];
        if (choices.count > 0) {
            NSDictionary *firstChoice = choices[0];
            NSDictionary *message = firstChoice[@"message"];
            NSString *content = message[@"content"];
            
            if (content) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(content, nil);
                });
                return;
            }
        }
        
        NSError *unexpectedError = [NSError errorWithDomain:@"AIService" 
                                                       code:1003 
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Unexpected response format"}];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, unexpectedError);
        });
    }];
    
    [task resume];
}

@end
