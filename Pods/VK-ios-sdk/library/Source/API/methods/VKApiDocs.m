//
//  VKApiDocs.m
//
//  Copyright (c) 2016 VK.com
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

#import "VKApiBase.h"
#import "VKApiDocs.h"
#import "VKDocs.h"

/**
 Builds requests for API.docs part
 */
@implementation VKApiDocs : VKApiBase

- (VKRequest *)get {
    return [self prepareRequestWithMethodName:@"get"
                                   parameters:nil
                                   modelClass:[VKDocsArray class]];
}

- (VKRequest *)get:(NSInteger)count {
    return [self prepareRequestWithMethodName:@"get"
                                   parameters:@{VK_API_COUNT: @(count)}
                                   modelClass:[VKDocsArray class]];
}

- (VKRequest *)get:(NSInteger)count andOffset:(NSInteger)offset {
    return [self prepareRequestWithMethodName:@"get"
                                 parameters:@{
                                     VK_API_COUNT   : @(count),
                                     VK_API_OFFSET  : @(offset)
                                 }
                                 modelClass:[VKDocsArray class]];
}

- (VKRequest *)get:(NSInteger)count andOffset:(NSInteger)offset andOwnerID:(NSInteger)ownerID {
    return [self prepareRequestWithMethodName:@"get"
                                   parameters:@{
                                       VK_API_COUNT    : @(count),
                                       VK_API_OFFSET   : @(offset),
                                       VK_API_OWNER_ID : @(ownerID)
                                   }
                                   modelClass:[VKDocsArray class]];
}

- (VKRequest *)getByID:(NSArray *)IDs {
    return [self prepareRequestWithMethodName:@"getById"
                                   parameters:@{@"docs" : IDs}
                                   modelClass:[VKDocsArray class]];
}

- (VKRequest *)getUploadServer {
    return [self prepareRequestWithMethodName:@"getUploadServer"
                                   parameters:nil];
}

- (VKRequest *)getUploadServer:(NSInteger)group_id {
    return [self prepareRequestWithMethodName:@"getUploadServer"
                                   parameters:@{VK_API_GROUP_ID : @(group_id)}];
}

- (VKRequest *)getWallUploadServer {
    return [self prepareRequestWithMethodName:@"getWallUploadServer"
                                   parameters:nil];
}

- (VKRequest *)getWallUploadServer:(NSInteger)group_id {
    return [self prepareRequestWithMethodName:@"getWallUploadServer"
                                   parameters:@{VK_API_GROUP_ID : @(group_id)}];
}

- (VKRequest *)save:(NSString *)file {
    return [self prepareRequestWithMethodName:@"save"
                                   parameters:@{VK_API_FILE : file}
                                   modelClass:[VKDocsArray class]];
}

- (VKRequest *)save:(NSString *)file andTitle:(NSString *)title {
    return [self prepareRequestWithMethodName:@"save"
                                   parameters:@{
                                       VK_API_FILE   : file,
                                       VK_API_TITLE  : title,
                                   }
                                   modelClass:[VKDocsArray class]];
}


- (VKRequest *)save:(NSString *)file andTitle:(NSString *)title andTags:(NSString *)tags {
    return [self prepareRequestWithMethodName:@"save"
                                   parameters:@{
                                       VK_API_FILE   : file,
                                       VK_API_TITLE  : title,
                                       VK_API_TAGS   : tags
                                   }
                                   modelClass:[VKDocsArray class]];
}

- (VKRequest *)delete:(NSInteger)ownerID andDocID:(NSInteger)docID {
    return [self prepareRequestWithMethodName:@"delete"
                                   parameters:@{
                                       VK_API_OWNER_ID : @(ownerID),
                                       VK_API_DOC_ID   : @(docID),
                                   }];
}

- (VKRequest *)add:(NSInteger)ownerID andDocID:(NSInteger)docID {
    return [self prepareRequestWithMethodName:@"add"
                                   parameters:@{
                                       VK_API_OWNER_ID   : @(ownerID),
                                       VK_API_DOC_ID     : @(docID)
                                   }];
}

- (VKRequest *)add:(NSInteger)ownerID andDocID:(NSInteger)docID andAccessKey:(NSString *)accessKey {
    return [self prepareRequestWithMethodName:@"add"
                                   parameters:@{
                                       VK_API_OWNER_ID   : @(ownerID),
                                       VK_API_DOC_ID     : @(docID),
                                       VK_API_ACCESS_KEY : accessKey
                                   }];
}

- (VKRequest *)search:(NSString *)query {
    return [self prepareRequestWithMethodName:@"search"
                                   parameters:@{VK_API_Q : query}
                                   modelClass:[VKDocsArray class]];
}

- (VKRequest *)search:(NSString *)query count:(NSInteger)count {
    return [self prepareRequestWithMethodName:@"search"
                                   parameters:@{
                                       VK_API_Q     : query,
                                       VK_API_COUNT : @(count)
                                   }
                                   modelClass:[VKDocsArray class]];
}

- (VKRequest *)search:(NSString *)query count:(NSInteger)count andOffset:(NSInteger)offset {
    return [self prepareRequestWithMethodName:@"search"
                                   parameters:@{
                                       VK_API_Q      :  query,
                                       VK_API_COUNT  : @(count),
                                       VK_API_OFFSET : @(offset)
                                   }
                                   modelClass:[VKDocsArray class]];
}

- (VKRequest *)edit:(NSInteger)docID title:(NSString *)title {
    return [self prepareRequestWithMethodName:@"edit"
                                   parameters:@{
                                       VK_API_DOC_ID : @(docID),
                                       VK_API_TITLE  : title
                                   }];
}

- (VKRequest *)edit:(NSInteger)docID title:(NSString *)title tags:(NSString *)tags {
    return [self prepareRequestWithMethodName:@"edit"
                                   parameters:@{
                                       VK_API_DOC_ID : @(docID),
                                       VK_API_TITLE  : title,
                                       VK_API_TAGS   : tags
                                   }];
}

- (VKRequest *)edit:(NSInteger)ownerID docID:(NSInteger)docID title:(NSString *)title {
    return [self prepareRequestWithMethodName:@"edit"
                                   parameters:@{
                                       VK_API_OWNER_ID : @(ownerID),
                                       VK_API_DOC_ID   : @(docID),
                                       VK_API_TITLE    : title
                                   }];
}

- (VKRequest *)edit:(NSInteger)ownerID docID:(NSInteger)docID title:(NSString *)title tags:(NSString *)tags {
    return [self prepareRequestWithMethodName:@"edit"
                                   parameters:@{
                                       VK_API_OWNER_ID  : @(ownerID),
                                       VK_API_DOC_ID    : @(docID),
                                       VK_API_TITLE     : title,
                                       VK_API_TAGS      : tags
                                   }];
}


@end
