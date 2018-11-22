//
//  ICFeedURLScraper.h
//  ICFeedParser
//
//  Created by Martin Hering on 18.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ICFeedURLScraperDelegate;

@interface ICFeedURLScraper : NSOperation {

}

+ (ICFeedURLScraper*) feedURLScraperWithURL:(NSURL*)url;
@property (nonatomic, readonly, strong) NSURL* url;
@property (nonatomic, weak) id<ICFeedURLScraperDelegate> delegate;

+ (NSURL*) scrapedFeedURLWithiTunesURL:(NSURL*)url;
@end


@protocol ICFeedURLScraperDelegate
- (void) feedURLScraper:(ICFeedURLScraper*)scraper didScrapeFeedURL:(NSURL*)url;
- (void) feedURLScraper:(ICFeedURLScraper*)scraper didEndWithError:(NSError*)error;
@end