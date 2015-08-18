//
//  VLSessionManager.m
//  test3
//
//  Created by Andrew Wells on 8/4/15.
//  Copyright (c) 2015 Andrew Wells. All rights reserved.
//

#import "VLSessionManager.h"
#import "VLUrlParser.h"
#import <UIKit/UIKit.h>

#import "VLUserCache.h"
#import <VinliNet/VinliSDK.h>

static NSString * VLSessionManagerClientIdDemo = @"3d0de990-6491-47cf-afda-e6855e7cd1c8";
static NSString * VLSessionManagerClientIdDev = @"f06e03c5-dcb8-4d69-b060-29e39dd98512";
static NSString * VLSessionManagerClientIdProd = @"fed505a9-021c-49b2-9cc9-576e9766b9de";

static NSString * VLSessionManagerHostDemo = @"-demo.vin.li";
static NSString * VLSessionManagerHostDev = @"-dev.vin.li";

static NSString * VLSessionManagerCachedSessionsKey = @"VLSessionManagerCachedSessionsKey";


@interface VLSessionManager ()
@property (strong, nonatomic) VLUrlParser *urlParser;
@property (copy, nonatomic) AuthenticationCompletion authenticationCompletionBlock;

@property (strong, nonatomic) VLService* service;
@property (strong, nonatomic) VLSession* currentSession;
@property (strong, nonatomic) NSDictionary* cachedSessions;
@end

@implementation VLSessionManager

#pragma mark - Accessors and Mutators

- (void)setClientId:(NSString *)clientId
{
    _clientId = clientId;
    self.urlParser.clientId = clientId;
}

- (void)setRedirectUri:(NSString *)redirectUri
{
    _redirectUri = redirectUri;
    self.urlParser.redirectUri = redirectUri;
}

- (VLService *)service
{
    if (!_service)
    {
        _service = [[VLService alloc] init];
#if DEBUG
        _service.host = VLSessionManagerHostDev;
#endif
    }
    return _service;
}

- (VLSession *)currentSession
{
    return _service.session;
}

#pragma mark - Initialization

+ (id)sharedManager {
    static VLSessionManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.urlParser = [[VLUrlParser alloc] init];
        self.cachedSessions = [[NSUserDefaults standardUserDefaults] objectForKey:VLSessionManagerCachedSessionsKey];
    }
    return self;
}

#pragma mark - Session Management

- (void)cacheSession:(VLSession *)session
{
    if (!session) {
        return;
    }
    
    @synchronized(self.cachedSessions)
    {
        NSMutableDictionary* mutableSessionsCache = [self.cachedSessions mutableCopy];
        if (!mutableSessionsCache)
        {
            mutableSessionsCache = [NSMutableDictionary new];
        }
        
        NSData *encodedSession = [NSKeyedArchiver archivedDataWithRootObject:session];
        [mutableSessionsCache setObject:encodedSession forKey:session.userId];
        self.cachedSessions = [mutableSessionsCache copy];
        
        [[NSUserDefaults standardUserDefaults] setObject:self.cachedSessions forKey:VLSessionManagerCachedSessionsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)handleCustomURL:(NSURL *)url
{
    // TODO: Do we still need VLUserCache
    VLUserCache* userCache = [self.urlParser parseUrl:url];
    
    // PUMPKIN
    if (!userCache) {
        return;
    }
     [userCache save];
    
    [self.service useSession:[[VLSession alloc] initWithAccessToken:userCache.accessToken userId:userCache.userId]];
    [self cacheSession:self.currentSession];
    
    if (self.authenticationCompletionBlock)
    {
        self.authenticationCompletionBlock(self.currentSession, nil);
        self.authenticationCompletionBlock = nil;
    }
    
}

- (void)callMyVinliApp
{
    
    // TODO: Add delegate methods here to ask client if we should do this
    NSURL* url = [self.urlParser buildUrl];
    
    if (![[UIApplication sharedApplication] openURL:url])
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:@"You must download the MyVinli app to continue."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Go to AppStore"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  NSString *iTunesLink = @"itms://itunes.apple.com/us/app/apple-store/id375380948?mt=8";
                                                                  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
                                                              }];
        
        [alert addAction:defaultAction];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                                 [alert removeFromParentViewController];
                                                             }];
        [alert addAction:cancelAction];
        
        [[[UIApplication sharedApplication].windows[0] rootViewController] presentViewController:alert animated:YES completion:nil];
        
    }

}

- (void)getSessionForUserWithId:(NSString *)userId completion:(AuthenticationCompletion)onCompletion
{
    // Check if current session user matches userid
    if ([self.currentSession.userId isEqualToString:userId])
    {
        // TODO: validate token
        if (onCompletion) { onCompletion (self.currentSession, nil); }
        return;
    }
    
    // Check user session in the cach
    VLSession* cachedSession = (VLSession *)[NSKeyedUnarchiver unarchiveObjectWithData:[self.cachedSessions objectForKey:userId]];
    if (cachedSession)
    {
        // validate token
        [self.service useSession:cachedSession];
        if (onCompletion) { onCompletion(self.currentSession, nil) ; }
        return;
    }
    
    // Call MyVinli to authenticate
    self.authenticationCompletionBlock = onCompletion;
    [self callMyVinliApp];
    
}



@end