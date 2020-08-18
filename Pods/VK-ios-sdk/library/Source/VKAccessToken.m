//
//  VKAccessToken.m
//
//  Copyright (c) 2014 VK.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  --------------------------------------------------------------------------------
//

#import "VKAccessToken.h"
#import "VKSdk.h"

static NSString *const ACCESS_TOKEN = @"access_token";
static NSString *const EXPIRES_IN = @"expires_in";
static NSString *const USER_ID = @"user_id";
static NSString *const SECRET = @"secret";
static NSString *const EMAIL = @"email";
static NSString *const HTTPS_REQUIRED = @"https_required";
static NSString *const CREATED = @"created";
static NSString *const PERMISSIONS = @"permissions";

@interface VKAccessToken () {
@protected
    NSString *_accessToken;
    NSString *_userId;
    NSString *_secret;
    NSArray *_permissions;
    BOOL _httpsRequired;
    NSInteger _expiresIn;
    VKUser *_localUser;

}
@property(nonatomic, readwrite, copy) NSString *accessToken;

@end

@implementation VKAccessToken

#pragma mark - Creating

+ (instancetype)tokenWithToken:(NSString *)accessToken
                        secret:(NSString *)secret
                        userId:(NSString *)userId {

    return [[self alloc] initWithToken:accessToken secret:secret userId:userId];
}

+ (instancetype)tokenFromUrlString:(NSString *)urlString {
    return [[self alloc] initWithUrlString:urlString];
}

- (instancetype)initWithToken:(NSString *)accessToken
                       secret:(NSString *)secret
                       userId:(NSString *)userId {
    self = [super init];
    if (self) {
        _accessToken = [accessToken copy];
        _secret = secret;
        _userId = userId;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _accessToken = [aDecoder decodeObjectForKey:ACCESS_TOKEN];
        _userId = [aDecoder decodeObjectForKey:USER_ID];
        _secret = [aDecoder decodeObjectForKey:SECRET];
        _email = [aDecoder decodeObjectForKey:EMAIL];
        _permissions = [self restorePermissions:[aDecoder decodeObjectForKey:PERMISSIONS]];

        _httpsRequired = [aDecoder decodeBoolForKey:HTTPS_REQUIRED];
        _expiresIn = [aDecoder decodeIntegerForKey:EXPIRES_IN];
        _created = [aDecoder decodeDoubleForKey:CREATED];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (self.accessToken) {
        [aCoder encodeObject:self.accessToken forKey:ACCESS_TOKEN];
    }
    if (self.userId) {
        [aCoder encodeObject:self.userId forKey:USER_ID];
    }
    if (self.secret) {
        [aCoder encodeObject:self.secret forKey:SECRET];
    }
    if (self.email) {
        [aCoder encodeObject:self.email forKey:EMAIL];
    }

    NSString *permissions = [self.permissions componentsJoinedByString:@","];
    if (permissions.length > 0) {
        [aCoder encodeObject:permissions forKey:PERMISSIONS];
    }

    [aCoder encodeBool:self.httpsRequired forKey:HTTPS_REQUIRED];
    [aCoder encodeInteger:self.expiresIn forKey:EXPIRES_IN];
    [aCoder encodeDouble:self.created forKey:CREATED];
}

- (NSArray *)restorePermissions:(NSString *)permissionsString {
    permissionsString = [permissionsString stringByReplacingOccurrencesOfString:@"(" withString:@""];
    permissionsString = [permissionsString stringByReplacingOccurrencesOfString:@")" withString:@""];
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *comp in [permissionsString componentsSeparatedByString:@","]) {
        [array addObject:[comp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    return array;
}

- (instancetype)initWithUrlString:(NSString *)urlString {

    self = [super init];
    if (self) {

        NSDictionary *parameters = [VKUtil explodeQueryString:urlString];
        _accessToken = [parameters[ACCESS_TOKEN] copy];
        _expiresIn = [parameters[EXPIRES_IN] integerValue];
        _userId = [parameters[USER_ID] copy];
        _secret = [parameters[SECRET] copy];
        _email = [parameters[EMAIL] copy];
        _httpsRequired = NO;

        _permissions = [self restorePermissions:parameters[PERMISSIONS]];

        if (parameters[HTTPS_REQUIRED]) {
            _httpsRequired = [parameters[HTTPS_REQUIRED] intValue] == 1;
        }

        _created = parameters[CREATED] ? [parameters[CREATED] floatValue] : [[NSDate new] timeIntervalSince1970];
        [self checkIfExpired];
    }

    return self;
}

- (instancetype)initWithVKAccessToken:(VKAccessToken *)token {
    if (self = [super init]) {
        _accessToken = [token.accessToken copy];
        _expiresIn = token.expiresIn;
        _userId = [token.userId copy];
        _secret = [token.secret copy];
        _httpsRequired = token.httpsRequired;
        _created = token.created;
        _permissions = [token.permissions copy];
        _email = [token.email copy];
        _localUser = token.localUser;
    }
    return self;
}

+ (instancetype)savedToken:(NSString *)defaultsKey {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
    if (data) {
        VKAccessToken *token = [self tokenFromUrlString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self save:defaultsKey data:token];
        return token;
    }
    return [self load:defaultsKey];
}

#pragma mark - Expire

- (BOOL)isExpired {
    return self.expiresIn > 0 && self.expiresIn + self.created < [[NSDate new] timeIntervalSince1970];
}

- (void)checkIfExpired {
    if (self.accessToken && self.isExpired) {
        [self notifyTokenExpired];
    }
}

#pragma mark -

- (NSString *)accessToken {
    if (_accessToken && self.isExpired) {
        [self notifyTokenExpired];
    }
    return _accessToken;
}

#pragma mark - Save / Load

- (void)saveTokenToDefaults:(NSString *)defaultsKey {
    [[self class] save:defaultsKey data:[self copy]];
}

- (id)copy {
    return [[VKAccessToken alloc] initWithVKAccessToken:self];
}

- (id)mutableCopy {
    return [[VKAccessTokenMutable alloc] initWithVKAccessToken:self];
}

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    /**
     Simple keychain requests
     Source: http://stackoverflow.com/a/5251820/1271424
     */
    
    return [@{(__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
            (__bridge id) kSecAttrService : service,
            (__bridge id) kSecAttrAccount : service,
            (__bridge id) kSecAttrAccessible : (__bridge id) kSecAttrAccessibleAfterFirstUnlock} mutableCopy];
}

+ (void)save:(NSString *)service data:(VKAccessToken *)token {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef) keychainQuery);
    keychainQuery[(__bridge id) kSecValueData] = [NSKeyedArchiver archivedDataWithRootObject:token];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef) keychainQuery, NULL);
    NSAssert(status == errSecSuccess, @"Unable to store VKAccessToken in keychain. OSStatus: %i. Error Description: https://www.osstatus.com/search/results?platform=all&framework=all&search=%i or https://developer.apple.com/reference/security/1658642-keychain_services", status, status);
}

+ (VKAccessToken *)load:(NSString *)service {
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    keychainQuery[(__bridge id) kSecReturnData] = (id) kCFBooleanTrue;
    keychainQuery[(__bridge id) kSecMatchLimit] = (__bridge id) kSecMatchLimitOne;
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef) keychainQuery, (CFTypeRef *) &keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *) keyData];
        }
        @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", service, e);
        }
        @finally {}
    }
    if (keyData) {
        CFRelease(keyData);
    }
    return ret;
}

+ (void)delete:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef) keychainQuery);
}

@end


@implementation VKAccessTokenMutable
@dynamic accessToken, expiresIn, userId, secret, permissions, httpsRequired, localUser;

- (void)setAccessToken:(NSString *)accessToken {
    _accessToken = [accessToken copy];
}

- (void)setExpiresIn:(NSInteger)expiresIn {
    _expiresIn = expiresIn;
}

- (void)setUserId:(NSString *)userId {
    _userId = [userId copy];
}

- (void)setSecret:(NSString *)secret {
    _secret = [secret copy];
}

- (void)setPermissions:(NSArray *)permissions {
    _permissions = [permissions copy];
}

- (void)setHttpsRequired:(BOOL)httpsRequired {
    _httpsRequired = httpsRequired;
}

- (void)setLocalUser:(VKUser *)localUser {
    _localUser = localUser;
}

@end
