//
//  LoginManager.m
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

#import "LoginManager.h"
#import <AuthenticationServices/AuthenticationServices.h>

@interface LoginManager () <ASWebAuthenticationPresentationContextProviding>
@property (nonatomic, strong) ASWebAuthenticationSession *session;
@property (nonatomic, weak) UIViewController *presentingVC;
@end

@implementation LoginManager

+ (instancetype) shared {
    static LoginManager *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = [[LoginManager alloc] init];
    });
    return m;
}

- (void) startLoginFromViewController:(UIViewController *)viewController
                              authURL:(NSURL *)authURL
                       callbackScheme:(NSString *)callbackScheme
                           completion:(LoginCompletion)completion
{
    self.presentingVC = viewController;
    __weak typeof(self) weakSelf = self;
    self.session = [[ASWebAuthenticationSession alloc] initWithURL:authURL
                                                 callbackURLScheme:callbackScheme
                                                 completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        self.session = nil;
        
        if (error) {
            completion(nil, error);
            return;
        }
        if (!callbackURL) {
            completion(nil, [NSError errorWithDomain:@"Auth"
                                                code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Missing callback URL"}]);
            return;
        }
        
        NSURLComponents *components = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
        NSString *code = nil;
        for (NSURLQueryItem *item in components.queryItems) {
            if ([item.name isEqualToString:@"code"]) {
                code = item.value;
                break;
            }
        }
        
        if (code.length == 0) {
            completion(nil, [NSError errorWithDomain:@"Auth" code:-2 userInfo:@{NSLocalizedDescriptionKey:@"Missing auth code"}]);
            return;
        }
        
        completion(code, nil);
    }];
    
    self.session.presentationContextProvider = self;
    self.session.prefersEphemeralWebBrowserSession = YES;
    
    BOOL started = [self.session start];
    if (!started) {
        completion(nil, [NSError errorWithDomain:@"Auth" code:-3 userInfo:@{NSLocalizedDescriptionKey:@"Failed to start auth session"}]);
    }
}


- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
    return self.presentingVC.view.window;
}

- (void)exchangeCodeForGitHubToken:(NSString *)code
                          tokenURL:(NSURL *)tokenURL
                          clientId:(NSString *)clientId
                      clientSecret:(NSString *)clientSecret
                       redirectURI:(NSString *)redirectURI
                        completion:(LoginCompletion)completion
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:tokenURL];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    NSString *body = [NSString stringWithFormat:
                      @"client_id=%@&client_secret=%@&code=%@&redirect_uri=%@",
                      [self urlEncode:clientId],
                      [self urlEncode:clientSecret],
                      [self urlEncode:code],
                      [self urlEncode:redirectURI]];
    req.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionDataTask *task =
    [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data,
                                                                              NSURLResponse * _Nullable response,
                                                                              NSError * _Nullable error) {
        if (error) { completion(nil, error); return; }
        if (!data) {
            completion(nil, [NSError errorWithDomain:@"Auth" code:-10 userInfo:@{NSLocalizedDescriptionKey:@"Empty token response"}]);
            return;
        }

        NSError *jsonErr = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
        if (jsonErr || ![json isKindOfClass:[NSDictionary class]]) {
            NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            completion(nil, [NSError errorWithDomain:@"Auth" code:-11 userInfo:@{NSLocalizedDescriptionKey: raw ?: @"Invalid token JSON"}]);
            return;
        }

        NSString *accessToken = json[@"access_token"];
        if (accessToken.length == 0) {
            completion(nil, [NSError errorWithDomain:@"Auth" code:-12 userInfo:@{NSLocalizedDescriptionKey:@"Missing access_token"}]);
            return;
        }

        completion(accessToken, nil);
    }];

    [task resume];
}

- (void)validateToken:(NSString *)accessToken
           validateURL:(NSURL *)validateURL
            completion:(void(^)(BOOL isValid))completion
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:validateURL];
    [req setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (error) { completion(NO); return; }

        NSInteger status = 0;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            status = ((NSHTTPURLResponse *)response).statusCode;
        }
        completion(status >= 200 && status < 300);
    }];
    [task resume];
}

- (NSString *)urlEncode:(NSString *)s {
    NSCharacterSet *allowed = [NSCharacterSet URLQueryAllowedCharacterSet];
    return [s stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: s;
}
@end
