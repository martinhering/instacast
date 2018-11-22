//
//  Instacast_Tests.m
//  Instacast Tests
//
//  Created by Martin Hering on 26.06.13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "ICMetadataParser.h"
#import "_ICMetadataPSCParser.h"
#import "ICMetadataExporter.h"

@interface ICMetadata_Tests : XCTestCase

@end

@implementation ICMetadata_Tests

static inline void hxRunInMainLoop(void(^block)(BOOL *done)) {
    __block BOOL done = NO;
    block(&done);
    while (!done) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    }
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void) _assetPSCTestDataChapters:(NSArray*)chapters images:(NSArray*)images completion:(void (^)())completion
{
    // test chapters
    XCTAssertTrue([chapters count] == 10, @"psc data does not contain 10 chapters");
    
    XCTAssertEqualObjects(((ICMetadataChapter*)chapters[0]).title, @"Intro", @"first chapter title is not 'Intro'");
    
    CMTime t = ((ICMetadataChapter*)chapters[4]).start;
    XCTAssertEqual((long)CMTimeGetSeconds(t), 4019L, @"5th chapters start index is not %ld (%ld)", 4019L, (long)CMTimeGetSeconds(t));

    // test images
    XCTAssertTrue([images count] == 2, @"psc data does not contain 2 image");
    
    ICMetadataImage* image = (ICMetadataImage*)images[0];
    t = image.start;
    XCTAssertEqual((long)CMTimeGetSeconds(t), 6796L, @"1st image on 6th chapter start index is not %ld (%ld)", 6796L, (long)CMTimeGetSeconds(t));
    
        
    [image loadPlatformImageWithCompletion:^(id object) {

        XCTAssertNotNil(object, @"%@", @"image not loaded correctly");
        
        XCTAssertTrue([object isKindOfClass:[NSImage class]], @"image is not of type NSImage");
        
        NSImage* platformImage = (NSImage*)object;
        
        XCTAssertTrue(([platformImage size].width == 300), @"image width is not 300");
        XCTAssertTrue(([platformImage size].height == 300), @"image height is not 300");
        
        XCTAssertNotNil(image.data, @"%@", @"image data is not cached");
        
        [image loadPlatformImageWithCompletion:^(id object) {
            XCTAssertNotNil(object, @"%@", @"image not loaded correctly");
            XCTAssertTrue([object isKindOfClass:[NSImage class]], @"image is not of type NSImage");
            
            completion();
        }];
    }];
}


- (void) testPSCDataParser
{
    NSString* testDataFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"psc_test_data" ofType:@"txt"];
    NSData* data = [NSData dataWithContentsOfFile:testDataFile];
    
    XCTAssertNotNil(data, @"psc test data not available");
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataAsset* asset = [[ICMetadataAsset alloc] init];
    
        _ICMetadataPSCParser* parser = [[_ICMetadataPSCParser alloc] initWithData:data metadataAsset:asset];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            XCTAssertTrue(success, @"psc data not parsed sucessfully %@", error);
            
            [self _assetPSCTestDataChapters:asset.chapters images:asset.images completion:^(id platformImage) {
                *done = YES;
            }];
        }];
        
    });
}

- (void) testPSCDataIntegration
{
    NSString* testDataFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"psc_test_data" ofType:@"txt"];
    NSData* data = [NSData dataWithContentsOfFile:testDataFile];
    
    XCTAssertNotNil(data, @"psc test data not available");
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithPSCData:data];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            XCTAssertTrue(success, @"psc data not parsed sucessfully %@", error);
            
            [self _assetPSCTestDataChapters:parser.metadataAsset.chapters images:parser.metadataAsset.images completion:^(id platformImage) {
                *done = YES;
            }];
        }];
        
    });
}

- (void) testPSCURLIntegration
{
    NSURL* pscURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/psc_test_data.txt"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithPSCURL:pscURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            XCTAssertTrue(success, @"psc data not parsed sucessfully %@", error);
            
            [self _assetPSCTestDataChapters:parser.metadataAsset.chapters images:parser.metadataAsset.images completion:^(id platformImage) {
                *done = YES;
            }];
        }];
        
    });
}

- (void) testAssetURLIntegrationMP3Auphonic
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/chapters_images_auphonic.mp3"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            XCTAssertTrue(success, @"data not loaded sucessfully %@", error);
            
            NSArray* chapters = parser.metadataAsset.chapters;
            XCTAssertTrue([chapters count] == 5, @"chapter count is not 5");
            
            // test title
            ICMetadataChapter* chapter = chapters[3];
            XCTAssertEqualObjects(chapter.title, @"4. with Umlauts Üä", @"title of 4th chapter is not '4. with Umlauts Üä' (%@)", chapter.title);
            
            // test link
            chapter = chapters[2];
            XCTAssertEqualObjects(chapter.link, [NSURL URLWithString:@"http://de.wikipedia.org/wiki/Liste_von_Abk%C3%BCrzungen_%28Netzjargon%29%23P"], @"url of 3th chapter is not 'http://de.wikipedia.org/wiki/Liste_von_...' (%@)", chapter.link);
            
            // test time
            CMTime t = chapter.start;
            XCTAssertEqual((long)CMTimeGetSeconds(t), 45L, @"5th chapters start index is not %ld (%ld)", 45L, (long)CMTimeGetSeconds(t));
            
        
            NSArray* images = parser.metadataAsset.images;
            XCTAssertTrue([images count] == 3, @"images count is not 3");
            
            ICMetadataImage* image = images[1];
            XCTAssertEqualObjects(image.mimeType, @"image/jpeg", @"mime type of 2nd image is not 'image/jpeg' (%@)", image.mimeType);
            XCTAssertEqualObjects(image.label, @"3. Third Chapter", @"label of 2nd image is not '3. Third Chapter' (%@)", image.label);
            
            t = image.start;
            XCTAssertEqual((long)CMTimeGetSeconds(t), 45L, @"start of 2nd image is not %ld (%ld)", 45L, (long)CMTimeGetSeconds(t));
            
            t = image.end;
            XCTAssertEqual((long)CMTimeGetSeconds(t), 75L, @"end of 2nd image is not %ld (%ld)", 75L, (long)CMTimeGetSeconds(t));
            
            
            [image loadPlatformImageWithCompletion:^(id object) {
                
                XCTAssertNotNil(object, @"image not loaded correctly");
                
                XCTAssertTrue([object isKindOfClass:[NSImage class]], @"image is not of type NSImage");
                
                NSImage* platformImage = (NSImage*)object;
                
                XCTAssertTrue(([platformImage size].width == 1200), @"image width is not 1200 (%lf)", [platformImage size].width);
                XCTAssertTrue(([platformImage size].height == 804), @"image height is not 804 (%lf)", [platformImage size].height);
                
                *done = YES;
            }];
        }];
        
    });
}

- (void) testAssetURLIntegrationM44Garageband
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/chapters_garageband.m4a"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            XCTAssertTrue(success, @"data not loaded sucessfully %@", error);
            
            
            
            
            *done = YES;   
        }];
        
    });
}

- (void) testAssetURLIntegrationM4AAuphonic
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/chapters_images_auphonic.m4a"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            XCTAssertTrue(success, @"data not loaded sucessfully %@", error);
            
            
            NSArray* chapters = parser.metadataAsset.chapters;
            XCTAssertTrue([chapters count] == 5, @"chapter count is not 5");
            
            // test title
            ICMetadataChapter* chapter = chapters[3];
            XCTAssertEqualObjects(chapter.title, @"eins zwanzig", @"title of 4th chapter is not 'eins zwanzig' (%@)", chapter.title);
            
            // test link
            chapter = chapters[2];
            XCTAssertEqualObjects(chapter.link, [NSURL URLWithString:@"http://www.cpojer.net/"], @"url of 3th chapter is not 'http://www.cpojer.net/' (%@)", chapter.link);
            
            // test time
            CMTime t = chapter.start;
            XCTAssertEqual((long)CMTimeGetSeconds(t), 60L, @"start is not %ld (%ld)", 60L, (long)CMTimeGetSeconds(t));

            t = chapter.end;
            XCTAssertEqual((long)CMTimeGetSeconds(t), 80L, @"end is not %ld (%ld)", 80L, (long)CMTimeGetSeconds(t));
            
            
            chapter = chapters[4];
            XCTAssertEqualObjects(chapter.title, @"01:50", @"title is not auto generated correctly");
            
            
            
            NSArray* images = parser.metadataAsset.images;
            XCTAssertTrue([images count] == 5, @"images count is not 5 (%lu)", [images count]);
            
            ICMetadataImage* image = images[1];
            XCTAssertNotNil(image.item, @"metadata item should not be nil");
            
            t = image.start;
            XCTAssertEqual((long)CMTimeGetSeconds(t), 30L, @"start of 2nd image is not %ld (%ld)", 30L, (long)CMTimeGetSeconds(t));
            
            t = image.end;
            XCTAssertEqual((long)CMTimeGetSeconds(t), 60L, @"end of 2nd image is not %ld (%ld)", 60L, (long)CMTimeGetSeconds(t));
            
            
            [image loadPlatformImageWithCompletion:^(id object) {
                
                XCTAssertNotNil(object, @"image not loaded correctly");
                
                XCTAssertTrue([object isKindOfClass:[NSImage class]], @"image is not of type NSImage");
                
                NSImage* platformImage = (NSImage*)object;
                
                XCTAssertTrue(([platformImage size].width == 239), @"image width is not 239 (%lf)", [platformImage size].width);
                XCTAssertTrue(([platformImage size].height == 256), @"image height is not 256 (%lf)", [platformImage size].height);
                
                *done = YES;
            }];

        }];
        
    });
}

- (void) testMetadataLinkExtraction
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/nfm001.mp3"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            XCTAssertTrue(success, @"data not loaded sucessfully %@", error);
            
            NSArray* chapters = parser.metadataAsset.chapters;
            
            XCTAssertTrue([chapters count] == 26, @"chapter count is not 26");
            
            ICMetadataChapter* chapter2 = chapters[1];
            XCTAssertEqualObjects(chapter2.link, [NSURL URLWithString:@"https://www.facebook.com/nxtbgthng"], @"url is not 'https://www.facebook.com/nxtbgthng' (%@)", chapter2.link);
            
            ICMetadataChapter* chapter16 = chapters[15];
            XCTAssertNil(chapter16.link, @"link should be nil in this case");
            
            ICMetadataChapter* chapter3 = chapters[2];
            XCTAssertEqualObjects(chapter3.title, @"Skeuomorph", @"title is not 'Skeuomorph' (%@)", chapter3.title);
            
            ICMetadataChapter* chapter19 = chapters[19];
            XCTAssertEqualObjects(chapter19.title, @"Robb ♡ unicode", @"title is not 'Robb ♡ unicode' (%@)", chapter19.title);
            
            *done = YES;
            
        }];
    });
}

- (void) testImageResizing
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/chapters_images_auphonic.m4a"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            NSArray* images = parser.metadataAsset.images;
            XCTAssertTrue([images count] == 5, @"images count is not 5 (%lu)", [images count]);
            
            ICMetadataImage* image = images[1];
            [image loadPlatformImageScaleToWidth:320 completion:^(id object) {
                
                NSImage* platformImage = (NSImage*)object;
                
                XCTAssertTrue(([platformImage size].width == 320 || [platformImage size].height == 320), @"either width or height should be 320 (%f)", [platformImage size].width);
                
            }];
            
            *done = YES;
        }];
    });
}

- (void) testBogusMP4Chapters
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/schoene_ecken.m4a"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
    
            NSArray* chapters = parser.metadataAsset.chapters;
            XCTAssertTrue([chapters count] == 52, @"images count is not 52 (%lu)", [chapters count]);
            
            ICMetadataChapter* chapter8 = chapters[7];
            XCTAssertEqual((long)[chapter8 durationWithTrackDuration:0], 27L, @"duration should be 27 seconds (%f)", [chapter8 durationWithTrackDuration:0]);
            XCTAssertEqualObjects(chapter8.title, @"Das bunte Haus", @"title should be 'Das bunte Haus' (%@)", chapter8.title);
            XCTAssertEqualObjects(chapter8.linkLabel, @"Wikipedia: Mondrian", @"link label should be 'Wikipedia: Mondrian' (%@)", chapter8.linkLabel);
            
            
            *done = YES;
        }];
    });
}

- (void) testItunesPodcastMetadataWithIDv22Tags
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/itunes_podcast_id3v22.mp3"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {

            ICMetadataAsset* asset = parser.metadataAsset;
            
            XCTAssertTrue(asset.podcast, @"podcast flag is not true (%d)", asset.podcast);
            XCTAssertEqualObjects(asset.episodeGuid, @"6088 at http://www.thisamericanlife.org", @"episodeGuid should be '6088 at http://www.thisamericanlife.org' (%@)", asset.episodeGuid);
            XCTAssertEqualObjects(asset.feedURL, [NSURL URLWithString:@"http://feeds.thisamericanlife.org/talpodcast"], @"feedURL should be 'http://feeds.thisamericanlife.org/talpodcast' (%@)", asset.feedURL);
            
            XCTAssertEqual((long)[asset.podcastDescription length], 1653L, @"show notes should be 1653 characters long (%ld)", (long)[asset.podcastDescription length]);
            
            *done = YES;
        }];
    });
}

- (void) testItunesPodcastMetadataWithIDv24Tags
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/itunes_podcast_id3v24.mp3"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            ICMetadataAsset* asset = parser.metadataAsset;
            
            XCTAssertTrue(asset.podcast, @"podcast flag is not true (%d)", asset.podcast);
            XCTAssertEqualObjects(asset.episodeGuid, @"513abd71e4b0fe58c655c105:513abd71e4b0fe58c655c111:52862536e4b0941019e9c597", @"episodeGuid should be '513abd71e4b0fe58c655c105:513abd71e4b0fe58c655c111:52862536e4b0941019e9c597' (%@)", asset.episodeGuid);
            XCTAssertEqualObjects(asset.feedURL, [NSURL URLWithString:@"http://atp.fm/episodes?format=rss"], @"feedURL should be 'http://atp.fm/episodes?format=rss' (%@)", asset.feedURL);
            
            XCTAssertEqual((long)[asset.podcastDescription length], 95L, @"show notes should be 95 characters long (%ld)", (long)[asset.podcastDescription length]);
            
            *done = YES;
        }];
    });
}

- (void) testItunesPodcastMetadataWithiTunesTags
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/itunes_podcast_itunestags.m4a"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            ICMetadataAsset* asset = parser.metadataAsset;
            
            XCTAssertTrue(asset.podcast, @"podcast flag is not true (%d)", asset.podcast);
            XCTAssertEqualObjects(asset.episodeGuid, @"http://www.schoene-ecken.de/?p=1827", @"episodeGuid should be 'http://www.schoene-ecken.de/?p=1827' (%@)", asset.episodeGuid);
            XCTAssertEqualObjects(asset.feedURL, [NSURL URLWithString:@"http://www.schoene-ecken.de/feed/podcast/"], @"feedURL should be 'http://www.schoene-ecken.de/feed/podcast/' (%@)", asset.feedURL);
            
            XCTAssertEqual((long)[asset.podcastDescription length], 348L, @"show notes should be 348 characters long (%ld)", (long)[asset.podcastDescription length]);
            
            *done = YES;
        }];
    });
}
/*
- (void) testITunesPodcastMetadataExportIDv22Tags
{
    NSURL* assetURL = [NSURL URLWithString:@"http://assets.vemedio.com/test_data/id3v22.mp3"];
    
    hxRunInMainLoop(^(BOOL *done) {
        
        ICMetadataParser* parser = [[ICMetadataParser alloc] initWithAssetURL:assetURL];
        [parser loadAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
            
            ICMetadataAsset* asset = parser.metadataAsset;
            
            ICMetadataExporter* exporter = [[ICMetadataExporter alloc] initWithAsset:asset];
            
            [exporter exportAsynchronouslyWithCompletionHandler:^(BOOL success, NSError *error) {
                
                *done = YES;
            }];
            
            
        }];
    });
}
 */
@end
