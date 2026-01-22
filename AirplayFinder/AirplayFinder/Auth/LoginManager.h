//
//  LoginManager.h
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LoginCompletion)(NSString * _Nullable accessToken, NSError * _Nullable error);

@interface LoginManager : NSObject

+ (instancetype) shared;
- (void)startLoginFromViewController:(UIViewController *)viewController
                             authURL: (NSURL *)authURL
                      callbackScheme: (NSString *) callbackScheme
                          completion:(LoginCompletion) completion;

- (void)exchangeCodeForGitHubToken:(NSString *)code
                          tokenURL:(NSURL *)tokenURL
                          clientId:(NSString *)clientId
                      clientSecret:(NSString *)clientSecret
                       redirectURI:(NSString *)redirectURI
                        completion:(LoginCompletion)completion;

- (void)validateToken:(NSString *)accessToken
          validateURL:(NSURL *)validateURL
           completion:(void(^)(BOOL isValid))completion;

@end

NS_ASSUME_NONNULL_END
