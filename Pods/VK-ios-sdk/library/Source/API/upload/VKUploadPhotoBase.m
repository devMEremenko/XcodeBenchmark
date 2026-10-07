//
//  VKPhotoUploadBase.m
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

#import "VKUploadPhotoBase.h"
#import "VKUploadImage.h"

extern inline NSString *VKKeyPathFromOperationState(VKOperationState state);

extern inline BOOL VKStateTransitionIsValid(VKOperationState fromState, VKOperationState toState, BOOL isCancelled);

@interface VKUploadPhotoBase ()
@property(nonatomic, readwrite, strong) NSOperation *executionOperation;
@end

@implementation VKUploadPhotoBase
@dynamic executionOperation;

- (instancetype)initWithImage:(UIImage *)image parameters:(VKImageParameters *)parameters {
    self = [super init];
    self.image = image;
    self.imageParameters = parameters;
    return self;
}

- (NSOperation *)createExecutionOperation {
    VKOperation *op = [VKUploadImageOperation operationWithUploadRequest:self];
    [op setResponseQueue:self.responseQueue];
    self.executionOperation = op;
    return op;
}

- (VKRequest *)getServerRequest {
    @throw [NSException exceptionWithName:@"Abstract function" reason:@"getServerRequest should be overriden" userInfo:nil];
}

- (VKRequest *)getSaveRequest:(VKResponse *)response {
    @throw [NSException exceptionWithName:@"Abstract function" reason:@"getSaveRequest should be overriden" userInfo:nil];
}

- (NSString *)methodName {
    return NSStringFromClass([self class]);
}

@end

@interface VKUploadImageOperation ()
@property(nonatomic, strong) VKUploadPhotoBase *uploadRequest;
@property(readwrite, nonatomic, assign) VKOperationState state;
@property(nonatomic, strong) VKRequest *lastLoadingRequest;
@end

@implementation VKUploadImageOperation
@dynamic state;

+ (instancetype)operationWithUploadRequest:(VKUploadPhotoBase *)uploadRequest {
    VKUploadImageOperation *operation = [VKUploadImageOperation new];
    operation.uploadRequest = uploadRequest;
    return operation;
}


- (void)start {
    void (^originalErrorBlock)(NSError *) = [_uploadRequest.errorBlock copy];
    __weak VKUploadImageOperation *weakSelf = self;
    _uploadRequest.errorBlock = ^(NSError *error) {
        [weakSelf finish];
        if (originalErrorBlock)
            originalErrorBlock(error);
    };
    self.state = VKOperationExecutingState;

    VKRequest *serverRequest = [_uploadRequest getServerRequest];
    serverRequest.responseQueue = self.responseQueue;
    __weak typeof(self) wself = self;
    serverRequest.completeBlock = ^(VKResponse *response) {
        __strong typeof(self) self = wself;
        NSData *imageData = nil;
        switch (self->_uploadRequest.imageParameters.imageType) {
            case VKImageTypeJpg:
                imageData = UIImageJPEGRepresentation(self->_uploadRequest.image, self->_uploadRequest.imageParameters.jpegQuality);
                break;

            case VKImageTypePng:
                imageData = UIImagePNGRepresentation(self->_uploadRequest.image);
                break;

            default:
                break;
        }
        self->_uploadRequest.image = nil;
        VKRequest *postFileRequest = [VKRequest photoRequestWithPostUrl:response.json[@"upload_url"]
                                                             withPhotos:@[[VKUploadImage uploadImageWithData:imageData andParams:self->_uploadRequest.imageParameters]]];
        postFileRequest.progressBlock = self->_uploadRequest.progressBlock;
        postFileRequest.responseQueue = self.responseQueue;
        self.lastLoadingRequest = postFileRequest;
        [postFileRequest executeWithResultBlock:^(VKResponse *response) {
            VKRequest *saveRequest = [self->_uploadRequest getSaveRequest:response];
            saveRequest.responseQueue = self.responseQueue;
            self.lastLoadingRequest = saveRequest;
            [saveRequest executeWithResultBlock:^(VKResponse *response) {
                response.request = self->_uploadRequest;

                if (self->_uploadRequest.completeBlock) self->_uploadRequest.completeBlock(response);
                [weakSelf finish];
            } errorBlock:self.uploadRequest.errorBlock];
        } errorBlock:self.uploadRequest.errorBlock];
    };
    serverRequest.errorBlock = _uploadRequest.errorBlock;
    self.lastLoadingRequest = serverRequest;
    [serverRequest start];
}

- (void)finish {
    self.state = VKOperationFinishedState;
    self.uploadRequest = nil;
    self.lastLoadingRequest = nil;
}

- (void)cancel {
    [super cancel];
    [self.lastLoadingRequest cancel];
}

@end
