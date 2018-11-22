//
//  _ICMetadataAssetParser.m
//  InstacastMac
//
//  Created by Martin Hering on 26.06.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "_ICMetadataAssetParser.h"
#import "ArbitraryDateParser.h"
#import <AVFoundation/AVFoundation.h>

@interface _ICMetadataAssetParser ()
@property (strong) AVAsset* asset;
@property (strong) ICMetadataAsset* metadataAsset;
@end


@implementation _ICMetadataAssetParser {
    NSMutableArray* _chapters;
    NSMutableArray* _images;
}

- (id) initWithAVAsset:(AVAsset*)asset metadataAsset:(ICMetadataAsset*)metadataAsset;
{
    if (self = [self init]) {
        _asset = asset;
        _metadataAsset = metadataAsset;
    }
    
    return self;
}

- (void) loadAsynchronouslyWithCompletionHandler:(ICMetadataCompletionHandler)completionHandler
{
    [self.asset loadValuesAsynchronouslyForKeys:@[ @"availableMetadataFormats", @"availableChapterLocales", @"duration" ] completionHandler:^(void) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSError *error = nil;
            AVKeyValueStatus formatsStatus = [self.asset statusOfValueForKey:@"availableMetadataFormats" error:&error];
            AVKeyValueStatus chaptersStatus = [self.asset statusOfValueForKey:@"availableChapterLocales" error:&error];
            AVKeyValueStatus durationStatus = [self.asset statusOfValueForKey:@"duration" error:&error];
            
            if (formatsStatus == AVKeyValueStatusLoaded && chaptersStatus == AVKeyValueStatusLoaded && chaptersStatus == durationStatus)
            {
                self.metadataAsset.duration = self.asset.duration;
                self.metadataAsset.video = NO;
                
                for(AVAssetTrack* assetTrack in self.asset.tracks)
                {
                    if ([assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) //track.enabled &&
                    {
                        CMFormatDescriptionRef formatDescription = (__bridge CMFormatDescriptionRef)[[assetTrack formatDescriptions] lastObject];
                        if (CMFormatDescriptionGetMediaSubType(formatDescription) != kCMVideoCodecType_JPEG) {
                            self.metadataAsset.video = YES;
                            
                            CGSize videodimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, true, true);
                            self.metadataAsset.pictureSize = videodimensions;
                            break;
                        }
                    }
                }
                

                NSArray* formats = [self.asset availableMetadataFormats];
                
                if ([formats containsObject:AVMetadataFormatID3Metadata]) {
                    [self _loadID3ChaptersCompletionHandler:completionHandler];
                }
                else if ([formats containsObject:AVMetadataFormatiTunesMetadata] || [formats containsObject:AVMetadataFormatQuickTimeMetadata]) {
                    [self _loadM4AChaptersCompletionHandler:completionHandler];
                }
                else {
                    completionHandler(NO,error);
                }
            }
            
            else {
                completionHandler(NO,error);
            }
        });
	}];
}

#pragma mark - MP3

#define CHAP_READ_4_BYTES (ntohl(*((uint32_t*)chapPtr)))
#define CHAP_READ_2_BYTES (ntohs(*((uint16_t*)chapPtr)))
#define CHAP_READ_1_BYTES *((uint8_t*)chapPtr)

- (NSStringEncoding) _stringEncodingWithID3EncodingValue:(uint8_t)encoding
{
    switch (encoding) {
        case 0:
            return NSISOLatin1StringEncoding;
        case 1:
            return NSUTF16StringEncoding;
        case 2:
            return NSUTF16BigEndianStringEncoding;
        case 3:
            return NSUTF8StringEncoding;
        default:
            break;
    }
    return NSISOLatin1StringEncoding;
}

- (void) _skipID3Tag:(const char**)bytes
{
    const char* chapPtr = *bytes;
    
    // jump over tag name
    *bytes+=4; chapPtr +=4;
    
    uint32_t c_size = CHAP_READ_4_BYTES;
    *bytes+=4; chapPtr +=4;
    
    //uint32_t c_flags = CHAP_READ_2_BYTES;
    *bytes+=2; chapPtr +=2;
    
    *bytes+=c_size;
}

- (NSString*) _textWithID3TITXTag:(const char**)bytes
{
    const char* chapPtr = *bytes;
    
    // jump over tag name
    *bytes+=4; chapPtr +=4;
    
    uint32_t c_size = CHAP_READ_4_BYTES;
    *bytes+=4; chapPtr +=4;
    
    //uint32_t c_flags = CHAP_READ_2_BYTES;
    *bytes+=2; chapPtr +=2;
    
    uint8_t c_text_encoding = CHAP_READ_1_BYTES;
    *bytes+=1; chapPtr +=1;
    
    NSStringEncoding encoding = [self _stringEncodingWithID3EncodingValue:c_text_encoding];
    
    unsigned long c_text_length = c_size - 1;
    char* c_chapter_title = calloc(c_text_length+1, 1);
    memcpy(c_chapter_title, chapPtr, c_text_length);
    *bytes+=c_text_length;
    
    NSString* title = [[NSString alloc] initWithBytesNoCopy:c_chapter_title length:c_text_length encoding:encoding freeWhenDone:YES];
    
    return title;
}

- (NSString*) _urlWithID3WXXXTag:(const char**)bytes description:(NSString**)description
{
    const char* chapPtr = *bytes;
    
    // jump over tag name
    *bytes+=4; chapPtr +=4;
    
    uint32_t c_size = CHAP_READ_4_BYTES;
    *bytes+=4; chapPtr +=4;
    
    //uint32_t c_flags = CHAP_READ_2_BYTES;
    *bytes+=2; chapPtr +=2;
    
    uint8_t c_text_encoding = CHAP_READ_1_BYTES;
    *bytes+=1; chapPtr +=1;
    
    NSStringEncoding encoding = [self _stringEncodingWithID3EncodingValue:c_text_encoding];
    
    unsigned long c_text_length = c_size - 1;
    char* c_text_string= calloc(c_text_length+1, 1);
    memcpy(c_text_string, chapPtr, c_text_length);
    *bytes+=c_text_length;
    
    unsigned long description_length = strlen(c_text_string);
    
    if (description) {
        *description = [[NSString alloc] initWithBytes:c_text_string length:description_length encoding:encoding];
    }
    
    NSString* urlString = [[NSString alloc] initWithBytes:c_text_string+description_length+1 length:c_text_length-description_length-1 encoding:NSISOLatin1StringEncoding];
    free(c_text_string);
    
    return urlString;
}

- (ICMetadataImage*) _imageWithID3APICTag:(const char**)bytes
{
    const char* chapPtr = *bytes;
    
    // jump over tag name
    *bytes+=4; chapPtr +=4;
    
    uint32_t c_size = CHAP_READ_4_BYTES;
    *bytes+=4; chapPtr +=4;
    
    //uint32_t c_flags = CHAP_READ_2_BYTES;
    *bytes+=2; chapPtr +=2;
    
    uint8_t c_text_encoding = CHAP_READ_1_BYTES;
    *bytes+=1; chapPtr +=1;
    
    NSStringEncoding encoding = [self _stringEncodingWithID3EncodingValue:c_text_encoding];
    
    unsigned long frame_length = c_size - 1;
    char* frame = malloc(frame_length);
    memcpy(frame, chapPtr, frame_length);
    *bytes+=frame_length;
    
    char* frame_ptr = frame;
    
    
    unsigned long mime_type_length = strlen(frame_ptr);
    NSString* mimeType = [[NSString alloc] initWithBytes:frame_ptr length:mime_type_length encoding:encoding];
    frame_ptr += mime_type_length+1;
    
    //char pictureType = frame_ptr[0];
    frame_ptr++;
    
    unsigned long description_length = strlen(frame_ptr);
    NSString* description = [[NSString alloc] initWithBytes:frame_ptr length:description_length encoding:encoding];
    frame_ptr += description_length+1;
    
    NSData* pictureData = [NSData dataWithBytes:frame_ptr length:frame_length-(frame_ptr-frame)];
    
    ICMetadataImage* image = [ICMetadataImage new];
    image.data = pictureData;
    image.mimeType = mimeType;
    image.label = description;
    
    return image;
}

#pragma mark -

- (NSURL*) urlByTrimmingNullCharacters:(NSURL*)url
{
    CFURLRef urlRef = (__bridge CFURLRef)url;
    
    UInt8* urlBuf = malloc(sizeof(UInt8)*8096);
    CFIndex urlBufSize = CFURLGetBytes(urlRef, urlBuf, 8096);
    
    NSInteger i=0;
    for(i=0; i<urlBufSize; i++) {
        if (urlBuf[i] != 0x00) {
            break;
        }
    }
    
    NSInteger j;
    for(j=urlBufSize-1; j>i; j--) {
        if (urlBuf[j] != 0x00) {
            break;
        }
    }
    
    CFURLRef trimmedURL = CFURLCreateAbsoluteURLWithBytes(kCFAllocatorDefault, urlBuf+i, j+1-i, kCFStringEncodingISOLatin1, NULL, true);
    
    free(urlBuf);
    
    return (__bridge_transfer NSURL*)trimmedURL;
}


- (void) _loadID3ChaptersCompletionHandler:(ICMetadataCompletionHandler)completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        NSMutableArray* chapters = [[NSMutableArray alloc] init];
        NSMutableArray* images = [[NSMutableArray alloc] init];
        
        NSArray* metadata = [self.asset metadataForFormat:AVMetadataFormatID3Metadata];
        
        self.metadataAsset.metadata = metadata;
        
        for(AVMetadataItem* item in metadata)
        {
            if (![item.key isKindOfClass:[NSNumber class]]) {
                continue;
            }
            
            unsigned long key = [(NSNumber*)item.key unsignedLongValue];
            if ((key == '\0WFD' || key == 'WFED') && [[item value] isKindOfClass:[NSURL class]]) {
                self.metadataAsset.feedURL = [self urlByTrimmingNullCharacters:(NSURL*)[item value]];
            }
            else if ((key == '\0TID' || key == 'TGID') && [[item value] isKindOfClass:[NSString class]]) {
                self.metadataAsset.episodeGuid = (NSString*)[item value];
            }
            else if ((key == '\0TDS' || key == 'TDES') && [[item value] isKindOfClass:[NSString class]]) {
                self.metadataAsset.podcastDescription = (NSString*)[item value];
            }
            else if ((key == '\0PCS' || key == 'PCST') && [[item value] isKindOfClass:[NSData class]]) {
                NSData* value = (NSData*)[item value];
                self.metadataAsset.podcast = [[NSData dataWithBytes:"\x00\x00\x00\x00" length:4] isEqual:value];
            }
            
            else if ((key == '\0TT2' || key == 'TIT2') && [[item value] isKindOfClass:[NSString class]]) {
                self.metadataAsset.title = (NSString*)[item value];
            }
            else if ((key == '\0TT3' || key == 'TIT3') && [[item value] isKindOfClass:[NSString class]]) {
                self.metadataAsset.subtitle = (NSString*)[item value];
            }
            else if ((key == '\0TAL' || key == 'TALB') && [[item value] isKindOfClass:[NSString class]]) {
                self.metadataAsset.album = (NSString*)[item value];
            }
            else if ((key == '\0TP1' || key == 'TPE1') && [[item value] isKindOfClass:[NSString class]]) {
                self.metadataAsset.artist = (NSString*)[item value];
            }
            else if ((key == '\0TDR' || key == 'TDRL') && [[item value] isKindOfClass:[NSString class]]) {
                ArbitraryDateParser* dateParser = [[ArbitraryDateParser alloc] init];
                self.metadataAsset.pubDate = [dateParser dateFromString:(NSString*)[item value]];
            }
        }


        // parse chapter tags
        NSArray* chapterTags = [AVMetadataItem metadataItemsFromArray:metadata withKey:@"CHAP" keySpace:AVMetadataKeySpaceID3];
        
        for(AVMetadataItem* chapItem in chapterTags)
        {
            NSData* dataValue = chapItem.dataValue;
            const char* chapData = [dataValue bytes];
            const char* chapPtr = chapData;
            
            char c_identifier[255];
            if (sscanf(chapPtr, "%s", c_identifier) != 1) {
                continue;
            }
            
            //NSString* identifier = [[NSString alloc] initWithCString:c_identifier encoding:NSISOLatin1StringEncoding];
            chapPtr += (strlen(c_identifier)+1);
            
            uint32_t c_start_ms = CHAP_READ_4_BYTES;
            chapPtr += 4;
            
            uint32_t c_end_ms = CHAP_READ_4_BYTES;
            chapPtr += 4;
            
            // discard byte offsets
            chapPtr += 8;
            
            NSString* chapterTitle = nil;
            NSString* chapterDescription = nil;
            NSString* chapterURL = nil;
            NSString* chapterURLDescription = nil;
            ICMetadataImage* chapterImage = nil;
            
            while (chapPtr-chapData < [dataValue length])
            {
                uint32_t c_tag = CHAP_READ_4_BYTES;
                
                switch (c_tag) {
                    case 'TIT2':
                        chapterTitle = [self _textWithID3TITXTag:&chapPtr];
                        break;
                    case 'TIT3':
                        chapterDescription = [self _textWithID3TITXTag:&chapPtr];
                        break;
                    case 'WCOM':
                    case 'WCOP':
                    case 'WOAF':
                    case 'WOAR':
                    case 'WOAS':
                    case 'WORS':
                    case 'WPAY':
                    case 'WPUB':
                        chapterURL = [self _textWithID3TITXTag:&chapPtr];
                        break;
                    case 'WXXX':
                        chapterURL = [self _urlWithID3WXXXTag:&chapPtr description:&chapterURLDescription];
                        break;
                    case 'APIC':
                        chapterImage = [self _imageWithID3APICTag:&chapPtr];
                        break;
                    default:
                        [self _skipID3Tag:&chapPtr];
                        break;
                }
            }
            
            ICMetadataChapter* chapter = [ICMetadataChapter new];
            chapter.start = CMTimeMake(c_start_ms, 1000);
            chapter.end = CMTimeMake(c_end_ms, 1000);
            chapter.title = [chapterTitle stringByDecodingHTMLEntities];
            chapter.label = chapterDescription;
            chapter.link = (chapterURL) ? [NSURL URLWithString:chapterURL] : nil;
            
            if (!_chapters) {
                _chapters = [NSMutableArray new];
            }
            [chapters addObject:chapter];
            
            
            if (chapterImage)
            {
                chapterImage.start = CMTimeMake(c_start_ms, 1000);
                chapterImage.end = CMTimeMake(c_end_ms, 1000);
                chapterImage.label = chapterTitle;
                
                if (!_images) {
                    _images = [NSMutableArray new];
                }
                [images addObject:chapterImage];
            }

        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.metadataAsset.chapters = [chapters sortedArrayUsingSelector:@selector(compare:)];
            self.metadataAsset.images = [images sortedArrayUsingSelector:@selector(compare:)];
            
            completionHandler(YES, nil);
        });
    });
}

#pragma mark - MP4

- (void) _loadM4AChaptersCompletionHandler:(ICMetadataCompletionHandler)completionHandler
{
    //NSArray* metadataFormats = [self.asset availableMetadataFormats];
    
    NSArray* metadata = [self.asset metadataForFormat:AVMetadataFormatiTunesMetadata];
    
    self.metadataAsset.metadata = metadata;
    
    for(AVMetadataItem* item in metadata)
    {
        if (![item.key isKindOfClass:[NSNumber class]]) {
            continue;
        }
        
        unsigned int key = [(NSNumber*)item.key unsignedIntValue];
        if (key == 'purl' && [[item value] isKindOfClass:[NSData class]]) {
            NSData* data = (NSData*)[item value];
            NSString* urlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (urlString) {
                self.metadataAsset.feedURL = [NSURL URLWithString:urlString];
            }
        }
        else if (key == 'egid' && [[item value] isKindOfClass:[NSData class]]) {
            NSData* data = (NSData*)[item value];
            self.metadataAsset.episodeGuid = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        else if (key == 'ldes' && [[item value] isKindOfClass:[NSString class]]) {
            self.metadataAsset.podcastDescription = (NSString*)[item value];
        }
        else if (key == 'pcst' && [[item value] isKindOfClass:[NSNumber class]]) {
            self.metadataAsset.podcast = [(NSNumber*)[item value] boolValue];
        }
        else if (key == 0xA96E616D && [[item value] isKindOfClass:[NSString class]]) {
            self.metadataAsset.title = (NSString*)[item value];
        }
        else if (key == 0xA9415254 && [[item value] isKindOfClass:[NSString class]]) {
            self.metadataAsset.artist = (NSString*)[item value];
        }
        else if (key == 0xA9616C62 && [[item value] isKindOfClass:[NSString class]]) {
            self.metadataAsset.album = (NSString*)[item value];
        }
        else if (key == 'desc' && [[item value] isKindOfClass:[NSString class]]) {
            self.metadataAsset.subtitle = (NSString*)[item value];
        }
        else if (key == 0xA9646179 && [[item value] isKindOfClass:[NSString class]]) {
            ArbitraryDateParser* dateParser = [[ArbitraryDateParser alloc] init];
            self.metadataAsset.pubDate = [dateParser dateFromString:(NSString*)[item value]];
        }
    }
    

    NSArray* chapterLocales = [self.asset availableChapterLocales];
    if ([chapterLocales count] == 0) {
        completionHandler(YES, nil);
        return;
    }
    
    // set first locale as default
    NSLocale* locale = [chapterLocales firstObject];
    
    // search for system locale match
    for(NSLocale* aLocale in chapterLocales)
    {
        NSString* lang = [[NSLocale componentsFromLocaleIdentifier:[locale localeIdentifier]] objectForKey:NSLocaleLanguageCode];
        NSString* currentLang = [[NSLocale componentsFromLocaleIdentifier:[[NSLocale systemLocale] localeIdentifier]] objectForKey:NSLocaleLanguageCode];
        if ([lang isEqualToString:currentLang]) {
            locale = aLocale;
            break;
        }
    }
    
    // get chapter items
    NSArray* commonKeys = [NSArray arrayWithObject:AVMetadataCommonKeyArtwork];
    NSArray* myChapterGroups = [self.asset chapterMetadataGroupsWithTitleLocale:locale containingItemsWithCommonKeys:commonKeys];
    //DebugLog(@"myChapterGroups %@", [myChapterGroups description]);
    
    // preload all titles
    NSInteger chaptersToLoad = 0;
    NSInteger imagesToLoad = 0;
    
    for(AVTimedMetadataGroup* itemGroup in myChapterGroups) {
        NSArray* items = [itemGroup items];
        
        for(AVMetadataItem* item in items) {
            if ([item.key isEqual:AVMetadataCommonKeyTitle]) {
                chaptersToLoad++;
            }
            else if ([item.key isEqual:AVMetadataCommonKeyArtwork]) {
                imagesToLoad++;
            }
        }
    }
    
    _chapters = [[NSMutableArray alloc] init];
    _images = [[NSMutableArray alloc] init];
    
    __block NSMutableDictionary* chapterIndex = [[NSMutableDictionary alloc] init];
    __block NSMutableDictionary* imageIndex = [[NSMutableDictionary alloc] init];
    
    __block NSInteger chaptersLoaded = 0;
    __block NSInteger imagesLoaded = 0;
    
    for(AVTimedMetadataGroup* itemGroup in myChapterGroups)
    {
        NSArray* items = [itemGroup items];
        for(AVMetadataItem* item in items)
        {
            if ([item.key isEqual:AVMetadataCommonKeyTitle])
            {
                [item loadValuesAsynchronouslyForKeys:@[@"value", @"extraAttributes"] completionHandler:^(void) {

                    //DebugLog(@"item %@", item);
                    
                    NSTimeInterval time = (NSTimeInterval)item.time.value / (NSTimeInterval)item.time.timescale;
                    NSString* indexKey = [NSString stringWithFormat:@"%ld", (long)time];
                    
                    ICMetadataChapter* chapter = chapterIndex[indexKey];
                    if (!chapter) {
                        chapter = [ICMetadataChapter new];
                        chapterIndex[indexKey] = chapter;
                    }
                    
                    if (chapter.start.value == 0) {
                        chapter.start = item.time;
                    }
                    if (chapter.end.value == 0) {
                        chapter.end = CMTimeAdd(item.time, item.duration);
                    }

                    chaptersLoaded++;
                    
                        
                    NSString* href = item.extraAttributes[@"HREF"];
                    chapter.link = (href) ? [NSURL URLWithString:[href copy]] : nil;
                    
                    
                    NSString* title = [item.value copyWithZone:nil];
                    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if (!href && [title length] > 0) {
                        chapter.title = title;
                        chapter.end = CMTimeAdd(item.time, item.duration);
                    }
                    else if (href && [title length] > 0) {
                        chapter.linkLabel = title;
                    }
                    

                    if (chaptersLoaded == chaptersToLoad)
                    {
                        _chapters = [[[chapterIndex allValues] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
                        
                        // remove chapter with no title and no significant time
                        [[_chapters copy] enumerateObjectsUsingBlock:^(ICMetadataChapter* chapter, NSUInteger idx, BOOL *stop) {
                            if ([chapter.title length] == 0 && [chapter durationWithTrackDuration:0] < 1) {
                                [_chapters removeObject:chapter];
                            }
                        }];

                        
                        if (imagesLoaded == imagesToLoad)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.metadataAsset.chapters = _chapters;
                                self.metadataAsset.images = _images;
                                completionHandler(YES, nil);
                            });
                        }
                    }

                }];
            }
            else if ([item.key isEqual:AVMetadataCommonKeyArtwork])
            {
                NSTimeInterval time = (NSTimeInterval)item.time.value / (NSTimeInterval)item.time.timescale;
                NSString* indexKey = [NSString stringWithFormat:@"%ld", (long)time];
                
                ICMetadataImage* image = imageIndex[indexKey];
                if (!image) {
                    image = [[ICMetadataImage alloc] init];
                    imageIndex[indexKey] = image;
                }
                
                image.start = item.time;
                image.end = CMTimeAdd(item.time, item.duration);
                image.item = item;
                
                imagesLoaded++;
                
                if (imagesLoaded == imagesToLoad)
                {
                    _images = [[[imageIndex allValues] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
                    
                    if (chaptersLoaded == chaptersToLoad)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.metadataAsset.chapters = _chapters;
                            self.metadataAsset.images = _images;
                            completionHandler(YES, nil);
                        });
                    }
                }
            }
        }
    }
}

@end
