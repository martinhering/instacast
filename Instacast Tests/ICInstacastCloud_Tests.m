//
//  ICInstacastCloud.m
//  InstacastMac
//
//  Created by Martin Hering on 11.05.14.
//  Copyright (c) 2014 Vemedio. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <VMFoundation/VMFoundation.h>

#import "ICCloudManager.h"
#import "ICCloudRequest.h"

@interface ICInstacastCloud_Tests : XCTestCase
@property (nonatomic, strong) NSOperationQueue* operationQueue;
@end

@implementation ICInstacastCloud_Tests

- (void)setUp
{
    [super setUp];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

static inline void hxRunInMainLoop(void(^block)(BOOL *done)) {
    __block BOOL done = NO;
    block(&done);
    while (!done) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    }
}

- (ICCloudAccount*) _account
{
    ICCloudAccount* account = [ICCloudManager sharedManager].account;
    
    if (!account) {
        account = [ICCloudAccount new];
		account.uuid = @"c90864fc-4f9e-4c9a-8efa-a752944e949c";
		account.accessToken = @"5e2de8d3c7fe570e865ab31520fb054a47217271";
		account.emailAddress = @"test@test.com";
    }
    
    return account;
}

- (void) testFalseLogin
{
    ICCloudAccount* account = [ICCloudAccount new];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initForAccountUpdate];
        cloudRequest.username = account.uuid;
        cloudRequest.password = account.accessToken;
        
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, NSDictionary* object) {
            
            XCTAssertTrue(false, @"object found?");
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(true, @"%@", error);
            
            *done = YES;
        };
        
        [self.operationQueue addOperation:cloudRequest];
        
    });
}

- (void) testCapabilities
{
    ICCloudAccount* account = [self _account];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initForAccountUpdate];
        cloudRequest.username = account.uuid;
        cloudRequest.password = account.accessToken;
        
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, NSDictionary* object) {
            
            XCTAssertNotNil(object, @"object is nil");
            XCTAssertTrue([object isKindOfClass:[NSDictionary class]], @"object must be a dictioanry");
            XCTAssertEqual(statusCode, 200, @"status code not ok: %ld", (long)statusCode);
            
            
            NSDictionary* user = object[@"user"];
                
            XCTAssertNotNil(user, @"user not available");
            XCTAssertEqualObjects(user[@"uuid"], account.uuid, @"user uuids do not match");
            
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            
            *done = YES;
        };
        
        [self.operationQueue addOperation:cloudRequest];
    
    });
}

- (void) testEmptySendEvent
{
    ICCloudAccount* account = [self _account];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initWithEvents:nil];
        cloudRequest.username = account.uuid;
        cloudRequest.password = account.accessToken;
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {

            XCTAssertEqual(statusCode, 400, @"status code not 'bad request': %ld", (long)statusCode);
            
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}


- (void) testSendEventWithInvalidDataType
{
    ICCloudAccount* account = [self _account];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        NSDictionary* events = @{@"url"  : @"test"};
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initWithEvents:(NSArray*)events];
        cloudRequest.username = account.uuid;
        cloudRequest.password = account.accessToken;
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            
            XCTAssertEqual(statusCode, 400, @"status code not 'bad request': %ld", (long)statusCode);
            
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}

- (void) testSendEventWithInvalidData
{
    ICCloudAccount* account = [self _account];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        NSDictionary* events = @{@"url"  : @"test"};
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initWithEvents:@[events]];
        cloudRequest.username = account.uuid;
        cloudRequest.password = account.accessToken;
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            
            XCTAssertEqual(statusCode, 400, @"status code not 'bad request': %ld", (long)statusCode);
            
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}

- (void) testSendEventWithInvalidData2
{
    ICCloudAccount* account = [self _account];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        NSDictionary* events = @{@"payment_url" : @"http://vemedio.com", @"event" : @"blubber" };
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initWithEvents:@[events]];
        cloudRequest.username = account.uuid;
        cloudRequest.password = account.accessToken;
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            
            XCTAssertEqual(statusCode, 400, @"status code not 'bad request': %ld", (long)statusCode);
            
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}


- (void) testSendEventWithValidData
{
    ICCloudAccount* account = [self _account];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        NSDictionary* events = @{@"payment_url" : @"http://vemedio.com", @"event" : @"starred" };
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initWithEvents:@[events]];
        cloudRequest.username = account.uuid;
        cloudRequest.password = account.accessToken;
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            
            XCTAssertEqual(statusCode, 200, @"status code not ok: %ld", (long)statusCode);
            
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}


- (void) testInitCreatingAccountExistingAccount
{
    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initForCreatingAccountWithEmail:@"info@vemedio.com" password:@"12345678"];
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            
            XCTAssertEqual(statusCode, 403, @"status code not forbidden: %ld", (long)statusCode);
            
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}

- (void) testInitCreatingNewAccount
{
    NSString* randomEmail = [NSString stringWithFormat:@"%@@vemedio.com", [NSString uuid]];
    __block NSString* accountUuid;
    __block NSString* accountAccessToken;
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initForCreatingAccountWithEmail:randomEmail password:@"12345678"];
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            
            XCTAssertEqual(statusCode, 201, @"status code not resource created: %ld", (long)statusCode);
            
            XCTAssertNotNil(object, @"object is nil");
            XCTAssertTrue([object isKindOfClass:[NSDictionary class]], @"object must be a dictionary");
            
            NSDictionary* user = object[@"user"];

            accountUuid = user[@"uuid"];
            accountAccessToken = user[@"access_token"];
            
            XCTAssertNotNil(accountUuid, @"created user uuid is nil");
            XCTAssertNotNil(accountAccessToken, @"created user access token is nil");

            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
 
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initForAccountUpdate];
        cloudRequest.username = accountUuid;
        cloudRequest.password = accountAccessToken;
        
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, NSDictionary* object) {
            
            XCTAssertNotNil(object, @"object is nil");
            XCTAssertTrue([object isKindOfClass:[NSDictionary class]], @"object must be a dictioanry");
            XCTAssertEqual(statusCode, 200, @"status code not ok: %ld", (long)statusCode);
            
            if ([object isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary* user = object[@"user"];
                
                XCTAssertNotNil(user, @"user not available");
                XCTAssertEqualObjects(user[@"uuid"], accountUuid, @"user uuids do not match");
            }
            
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            
            *done = YES;
        };
        
        [self.operationQueue addOperation:cloudRequest];
        
    });
}


- (void) testSigningIntoNonExistingAccount
{
    NSString* randomEmail = [NSString stringWithFormat:@"%@@vemedio.com", [NSString uuid]];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initForSigningIntoAccountWithEmail:randomEmail password:[NSString uuid]];
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            XCTAssertTrue(false, @"unexpected response");
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertEqual([error code], kCFURLErrorUserAuthenticationRequired, @"does not respond with 401");
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}

- (void) testSigningIntoExistingAccount
{

    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initForSigningIntoAccountWithEmail:@"info@vemedio.com" password:@"abcd1234"];
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            
            XCTAssertNotNil(object, @"object is nil");
            XCTAssertTrue([object isKindOfClass:[NSDictionary class]], @"object must be a dictioanry");
            XCTAssertEqual(statusCode, 200, @"status code not ok: %ld", (long)statusCode);
            
            NSDictionary* user = object[@"user"];
            
            XCTAssertNotNil(user, @"user not available");
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}

- (void) testForgotEmailOfNonExistingAccount
{
    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initForForgotPasswordForAccountWithEmail:[NSString uuid]];
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            XCTAssertEqual(statusCode, 200, @"status code not ok: %ld", (long)statusCode);
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}

- (void) testForgotEmailOfExistingAccount
{
    hxRunInMainLoop(^(BOOL *done) {
        
        ICCloudRequest* cloudRequest = [[ICCloudRequest alloc] initForForgotPasswordForAccountWithEmail:@"testmac@vemedio.com"];
        cloudRequest.didReturnWithObjectBlock = ^(NSInteger statusCode, id object) {
            XCTAssertEqual(statusCode, 200, @"status code not ok: %ld", (long)statusCode);
            XCTAssertNil(object, @"object must be nil");
            *done = YES;
        };
        cloudRequest.didReturnWithErrorBlock = ^(NSError* error) {
            XCTAssertTrue(false, @"%@", error);
            *done = YES;
        };
        [self.operationQueue addOperation:cloudRequest];
        
    });
}


@end
