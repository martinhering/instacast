//
//  ICUserDefaults.h
//  Instacast
//
//  Created by Martin Hering on 18.12.12.
//
//

#import "Defines.h"

NSString* InstacastErrorDomain = @"InstacastErrorDomain";

NSString* DirectoryThirdLanguageChoice = @"DirectoryThirdLanguageChoice";
NSString* DirectorySelectedLanguage = @"DirectorySelectedLanguage";

NSString* ShowApplicationBadgeForUnseen = @"ShowApplicationBadgeForUnseen";
NSString* LastRefreshSubscriptionDate = @"LastRefreshSubscriptionDate";
NSString* FirstLaunchDate = @"FirstLaunchDate";
NSString* MediaLibraryImportedFeedTitles = @"MediaLibraryImportedFeedTitles";
NSString* EnabledBackgroundPlayback = @"EnabledBackgroundPlayback";
NSString* WelcomeMessageVersion = @"WelcomeMessageVersion";

NSString* EnableCachingOver3G = @"EnableCachingOver3G";
NSString* EnableCachingImagesOver3G = @"EnableCachingImagesOver3G";
NSString* EnableRefreshingOver3G = @"EnableRefreshingOver3G";
NSString* EnableSyncingOver3G = @"EnableSyncingOver3G";

NSString* AutoCacheNewAudioEpisodes = @"AutoCacheNewAudioEpisodes";
NSString* AutoCacheNewVideoEpisodes = @"AutoCacheNewVideoEpisodes";
NSString* AutoCacheStorageLimit = @"AutoCacheStorageLimit";
NSString* UISoundEnabled = @"UISoundEnabled";
NSString* PlayerSkipBackPeriod = @"PlayerSkipBackPeriod";
NSString* PlayerSkipForwardPeriod = @"PlayerSkipForwardPeriod";
NSString* PlayerReplayAfterPause = @"ReplayAfterPause";
NSString* DropBoxRootPath = @"DropBoxRootPath";
NSString* LinkDropBox = @"LinkDropBox";

NSString* FeedSortOrder = @"FeedSortOrder";
NSString* FeedSortKey = @"FeedSortKey";

NSString* SortOrderNewerFirst = @"NewerFirst";
NSString* SortOrderOlderFirst = @"OlderFirst";

NSString* DefaultPlaybackSpeed = @"DefaultPlaybackSpeed";
NSString* EnableManualRefreshFinishedNotification = @"EnableManualRefreshFinishedNotification";
NSString* EnableManualDownloadFinishedNotification = @"EnableManualDownloadFinishedNotification";
NSString* EnableNewEpisodeNotification = @"EnableNewEpisodeNotification";

NSString* DisableAutoLock = @"DisableAutoLock";

NSString* EnableStreamingOver3G = @"EnableStreamingOver3G";

NSString* UIStateSelectedFeed = @"UIStateSelectedFeed";
NSString* UIStateSelectedEpisode = @"UIStateSelectedEpisode";

NSString* ReadLaterService = @"ReadLaterService";
NSString* ReadLaterServiceNone = @"None";
NSString* ReadLaterServiceInstapaper = @"Instapaper";
NSString* ReadLaterServiceReadability = @"Readability";
NSString* ReadLaterServiceReadItLater = @"Pocket";

NSString* AllowSendingDiagnostics = @"AllowSendingDiagnostics";
NSString* AutomaticallySendDiagnostics = @"AutomaticallySendDiagnostics";

NSString* SharingFullName = @"SharingFullName";
NSString* SharingTwitterHandle= @"SharingTwitterHandle";

NSString* AutoDeleteAfterFinishedPlaying = @"AutoDeleteAfterFinishedPlaying";
NSString* AutoDeleteAfterMarkedAsPlayed = @"AutoDeleteAfterMarkedAsPlayed";
NSString* AutoDeleteNewsMode = @"AutoDeleteNewsMode";

NSString* kDefaultShowUnavailableEpisodes = @"ShowUnavailableEpisodes";

NSString* kDefaultPlayerControls = @"PlayerControls";
NSString* kDefaultSwitchNightModeAutomatically = @"SwitchNightModeAutomatically";
NSString* kDefaultNightMode = @"NightMode";
NSString* kDefaultDontDeleteUpNextWhenChangingEpisode = @"DontDeleteUpNextWhenChangingEpisode";

#if TARGET_OS_IPHONE==1
#else
NSString* AutoRefresh = @"AutoRefresh";
#endif

NSString* kICDurationValueTransformer = @"ICDurationValueTransformer";
NSString* kICPubdateValueTransformer = @"ICPubdateValueTransformer";


NSString* kUIPersistenceMainSidebarItem = @"SelectedMainSidebarItem";
NSString* kUIPersistenceSubscriptionsSelectedFeedUID = @"SubscriptionsSelectedFeedUID";
NSString* kUIPersistenceSubscriptionsSearchTerm = @"SubscriptionsSearchTerm";
NSString* kUIPersistencePlaylistsSelectedPlaylistUID = @"DefaultPlaylistsSelectedPlaylistUID";
NSString* kUIPersistenceBookmarkSelectedEpisodeGUID = @"DefaultBookmarkSelectedEpisodeGUID";
