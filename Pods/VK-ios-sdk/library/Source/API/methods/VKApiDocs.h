//
//  VKApiDocs.h
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

#import "VKApiBase.h"

/**
 Builds requests for API.docs part
 */
@interface VKApiDocs : VKApiBase

/**
 *  Returns detailed information about user or community documents.
 *  https://vk.com/dev/docs.get
 *
 *  @return Request to load
 */
- (VKRequest *)get;

/**
 *   Returns detailed information about user or community documents.
 *   https://vk.com/dev/docs.get
 *
 *  @param count Number of documents to return.
 *
 *  @return Request to load
 */
- (VKRequest *)get:(NSInteger)count;

/**
 *  Returns detailed information about user or community documents.
 *  https://vk.com/dev/docs.get
 *
 *  @param count  Number of documents to return. By default, all documents.
 *  @param offset Offset needed to return a specific subset of documents.
 *
 *  @return Request to load
 */
- (VKRequest *)get:(NSInteger)count andOffset:(NSInteger)offset;

/**
 *  Returns detailed information about user or community documents.
 *  https://vk.com/dev/docs.get
 *
 *  @param count   Number of documents to return. By default, all documents.
 *  @param offset  Offset needed to return a specific subset of documents.
 *  @param ownerID ID of the user or community that owns the documents. Use a negative value to designate a community ID.
 *
 *  @return Request to load
 */
- (VKRequest *)get:(NSInteger)count andOffset:(NSInteger)offset andOwnerID:(NSInteger)ownerID;

/**
 *  Returns information about documents by their IDs.
 *  https://vk.com/dev/docs.getById
 *  @param IDs Document IDs.
 *
 *  @return Request to load
 */
- (VKRequest *)getByID:(NSArray *)IDs;

/**
 *  Returns the server address for document upload.
 *  https://vk.com/dev/docs.getUploadServer
 *
 *  @return Request to load
 */
- (VKRequest *)getUploadServer;

/**
 *  Returns the server address for document upload.
 *  https://vk.com/dev/docs.getUploadServer
 *
 *  @param group_id ID of the community the document will be uploaded to.
 *
 *  @return Request to load
 */
- (VKRequest *)getUploadServer:(NSInteger)group_id;

/**
 *  Returns the server address for document upload onto a user's or community's wall.
 *  https://vk.com/dev/docs.getWallUploadServer
 *
 *  @return Request to load
 */
- (VKRequest *)getWallUploadServer;

/**
 *  Returns the server address for document upload onto a user's or community's wall.
 *  https://vk.com/dev/docs.getWallUploadServer
 *
 *  @param group_id ID of the community the document will be uploaded to.
 *
 *  @return Request to load
 */
- (VKRequest *)getWallUploadServer:(NSInteger)group_id;

/**
 *  Saves a document after uploading it to a server.
 *  https://vk.com/dev/docs.save
 *
 *  @param file This parameter is returned when the file is uploaded to the server.
 *
 *  @return Request to load
 */
- (VKRequest *)save:(NSString *)file;

/**
 *  Saves a document after uploading it to a server.
 *  https://vk.com/dev/docs.save
 *
 *  @param file  This parameter is returned when the file is uploaded to the server.
 *  @param title Document title.
 *
 *  @return Request to load
 */
- (VKRequest *)save:(NSString *)file andTitle:(NSString *)title;

/**
 *  Saves a document after uploading it to a server.
 *  https://vk.com/dev/docs.save
 *
 *  @param file  This parameter is returned when the file is uploaded to the server.
 *  @param title Document title
 *  @param tags  Document tags
 *
 *  @return Request to load
 */
- (VKRequest *)save:(NSString *)file andTitle:(NSString *)title andTags:(NSString *)tags;

/**
 *  Deletes a user or community document.
 *  https://vk.com/dev/docs.delete
 *
 *  @param ownerID ID of the user or community that owns the document. Use a negative value to designate a community ID.
 *  @param docID   Document ID.
 *
 *  @return Request to load
 */
- (VKRequest *)delete:(NSInteger)ownerID andDocID:(NSInteger)docID;

/**
 *  Copies a document to a user's or community's document list.
 *  https://vk.com/dev/docs.add
 *
 *  @param ownerID   ID of the user or community that owns the document. Use a negative value to designate a community ID.
 *  @param docID     Document ID.
 *
 *  @return Request to load
 */
- (VKRequest *)add:(NSInteger)ownerID andDocID:(NSInteger)docID;

/**
 *  Copies a document to a user's or community's document list.
 *  https://vk.com/dev/docs.add
 *
 *  @param ownerID   ID of the user or community that owns the document. Use a negative value to designate a community ID.
 *  @param docID     Document ID.
 *  @param accessKey Access key. This parameter is required if access_key was returned with the document's data.
 *
 *  @return Request to load
 */
- (VKRequest *)add:(NSInteger)ownerID andDocID:(NSInteger)docID andAccessKey:(NSString *)accessKey;

/**
 *  Returns results of search
 *  https://vk.com/dev/docs.search
 *
 *  @param query  Search query
 *
 *  @return Request to load
 */
- (VKRequest *)search:(NSString *)query;

/**
 *  Returns results of search
 *  https://vk.com/dev/docs.search
 *
 *  @param query  Search query
 *  @param count  Number of documents to return.
 *
 *  @return Request to load
 */
- (VKRequest *)search:(NSString *)query count:(NSInteger)count;

/**
 *  Returns results of search
 *  https://vk.com/dev/docs.search
 *
 *  @param query  Search query
 *  @param count  Number of documents to return.
 *  @param offset Offset needed to return a specific subset of documents.
 *
 *  @return Request to load
 */
- (VKRequest *)search:(NSString *)query count:(NSInteger)count andOffset:(NSInteger)offset;

/**
 *  Edits a current user's document.
 *  https://vk.com/dev/docs.edit
 *
 *  @param docID  Document ID.
 *  @param title  New document title
 *
 *  @return Request to load
 */
- (VKRequest *)edit:(NSInteger)docID title:(NSString *)title;

/**
 *  Edits a current user's document.
 *  https://vk.com/dev/docs.edit
 *
 *  @param docID  Document ID.
 *  @param title  New document title
 *  @param tags   New document tags
 *
 *  @return Request to load
 */
- (VKRequest *)edit:(NSInteger)docID title:(NSString *)title tags:(NSString *)tags;

/**
 *  Edits a user's or community's document.
 *  https://vk.com/dev/docs.edit
 *
 *  @param ownerID  ID of the user or community that owns the document. Use a negative value to designate a community ID.
 *  @param docID    Document ID.
 *  @param title    New document title
 *
 *  @return Request to load
 */
- (VKRequest *)edit:(NSInteger)ownerID docID:(NSInteger)docID title:(NSString *)title;

/**
 *  Edits a user's or community's document.
 *  https://vk.com/dev/docs.edit
 *
 *  @param ownerID  ID of the user or community that owns the document. Use a negative value to designate a community ID.
 *  @param docID    Document ID.
 *  @param title    New document title
 *  @param tags     New document tags
 *
 *  @return Request to load
 */
- (VKRequest *)edit:(NSInteger)ownerID docID:(NSInteger)docID title:(NSString *)title tags:(NSString *)tags;



@end
