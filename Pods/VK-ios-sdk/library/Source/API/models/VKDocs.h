//
//  VKDocs.h
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

#import <Foundation/Foundation.h>
#import "VKApiObject.h"
#import "VKApiObjectArray.h"

@class VKPhoto;

@interface VKGraffiti : VKApiObject
@property(nonatomic, strong) NSString *src;
@property(nonatomic, strong) NSNumber *width;
@property(nonatomic, strong) NSNumber *height;
@end

@interface VKAudioMsg : VKApiObject
@property(nonatomic, strong) NSNumber *duration;
@property(nonatomic, strong) NSArray<NSNumber *> *waveform;
@property(nonatomic, strong) NSString *link_ogg;
@property(nonatomic, strong) NSString *link_mp3;
@end

/**
 Document preview data.
*/
@interface VKDocsPreview : VKApiObject
@property(nonatomic, strong) VKPhoto *photo;
@property(nonatomic, strong) VKGraffiti *graffiti;
@property(nonatomic, strong) VKAudioMsg *audio_msg;
@end

/**
 Docs type of VK API. See descriptions here https://vk.com/dev/doc
 */
@interface VKDocs : VKApiObject
@property(nonatomic, strong) NSNumber *id;
@property(nonatomic, strong) NSNumber *owner_id;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, strong) NSNumber *size;
@property(nonatomic, copy) NSString *ext;
@property(nonatomic, copy) NSString *url;
@property(nonatomic, strong) NSNumber *date;
@property(nonatomic, strong) NSNumber *type;
@property(nonatomic, strong) VKDocsPreview *preview;
@end

/**
 Array of API docs objects
 */
@interface VKDocsArray : VKApiObjectArray<VKDocs*>
@end
