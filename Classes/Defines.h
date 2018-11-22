//
//  ICUserDefaults.h
//  Instacast
//
//  Created by Martin Hering on 18.12.12.
//
//

#import <Foundation/Foundation.h>

extern NSString* InstacastErrorDomain;

extern NSString* DirectoryThirdLanguageChoice;
extern NSString* DirectorySelectedLanguage;

extern NSString* ShowApplicationBadgeForUnseen;
extern NSString* LastRefreshSubscriptionDate;
extern NSString* FirstLaunchDate;
extern NSString* MediaLibraryImportedFeedTitles;
extern NSString* EnabledBackgroundPlayback;

extern NSString* ActiveContentFilter;
extern NSString* WelcomeMessageVersion;
extern NSString* EnableCachingOver3G;
extern NSString* EnableCachingImagesOver3G;
extern NSString* EnableRefreshingOver3G;
extern NSString* EnableSyncingOver3G;

extern NSString* AutoCacheNewAudioEpisodes;
extern NSString* AutoCacheNewVideoEpisodes;

extern NSString* AutoCacheStorageLimit;
extern NSString* UISoundEnabled;
extern NSString* PlayerSkipBackPeriod;
extern NSString* PlayerSkipForwardPeriod;
extern NSString* PlayerReplayAfterPause;
extern NSString* DropBoxRootPath;
extern NSString* LinkDropBox;

extern NSString* FeedSortOrder;
extern NSString* FeedSortKey;
extern NSString* SortOrderNewerFirst;
extern NSString* SortOrderOlderFirst;

extern NSString* DefaultPlaybackSpeed;


extern NSString* EnableManualRefreshFinishedNotification;
extern NSString* EnableManualDownloadFinishedNotification;
extern NSString* EnableNewEpisodeNotification;

extern NSString* DisableAutoLock;
extern NSString* EnableStreamingOver3G;


extern NSString* UIStateSelectedFeed;
extern NSString* UIStateSelectedEpisode;

extern NSString* ReadLaterService;
extern NSString* ReadLaterServiceNone;
extern NSString* ReadLaterServiceInstapaper;
extern NSString* ReadLaterServiceReadability;
extern NSString* ReadLaterServiceReadItLater;

extern NSString* AllowSendingDiagnostics;
enum {
	DiagnosticsDontSend = 0,
	DiagnosticsAskBeforeSending = 1,
	DiagnosticsAutomaticallySend = 2
};
extern NSString* AutomaticallySendDiagnostics;

extern NSString* SharingFullName;
extern NSString* SharingTwitterHandle;

extern NSString* AutoDeleteAfterFinishedPlaying;
extern NSString* AutoDeleteAfterMarkedAsPlayed;
extern NSString* AutoDeleteNewsMode;

extern NSString* kDefaultShowUnavailableEpisodes;

extern NSString* kDefaultPlayerControls;
typedef NS_ENUM(NSInteger, DefaultPlayerControls) {
    kPlayerSeekingControls,
    kPlayerSeekingAndSkippingChaptersControls,
    kPlayerSkippingControls
};
extern NSString* kDefaultDontDeleteUpNextWhenChangingEpisode;

extern NSString* kDefaultSwitchNightModeAutomatically;
extern NSString* kDefaultNightMode;

#if TARGET_OS_IPHONE==1
#else
extern NSString* AutoRefresh;
enum {
    AutoRefreshNever = 1,
    AutoRefreshOncePerDay,
    AutoRefreshEvery12Hours,
    AutoRefreshEvery6Hours,
    AutoRefreshEveryHour,
    AutoRefreshEvery15Minutes,
};
typedef NSInteger AutoRefreshInterval;
#endif

extern NSString* kICDurationValueTransformer;
extern NSString* kICPubdateValueTransformer;

extern NSString* kUIPersistenceMainSidebarItem;
extern NSString* kUIPersistenceSubscriptionsSelectedFeedUID;
extern NSString* kUIPersistenceSubscriptionsSearchTerm;
extern NSString* kUIPersistencePlaylistsSelectedPlaylistUID;
extern NSString* kUIPersistenceBookmarkSelectedEpisodeGUID;
extern NSString* kUIPersistenceDirectorySearchSearchString;
extern NSString* kUIPersistenceDirectorySearchSelectedScopeIndex;

