//
//  NSBundle+VMFoundation.m
//  VMFoundation
//
//  Created by Martin Hering on 11/07/13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import "NSBundle+VMFoundation.h"
#import "NSString+VMFoundation.h"

#import <SystemConfiguration/SystemConfiguration.h>
#include <sys/sysctl.h>

#if TARGET_OS_IPHONE
#include <sys/socket.h>
#include <net/if.h>
#include <net/if_dl.h>
#else
#include <IOKit/IOKitLib.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IONetworkInterface.h>
#include <IOKit/network/IOEthernetController.h>
#endif

#if TARGET_OS_IPHONE
#else

// Returns an iterator containing the primary (built-in) Ethernet interface. The caller is responsible for
// releasing the iterator after the caller is done with it.
kern_return_t __FindEthernetInterfaces(io_iterator_t *matchingServices)
{
    kern_return_t    kernResult;
    mach_port_t      masterPort;
    CFMutableDictionaryRef  matchingDict;
    CFMutableDictionaryRef  propertyMatchDict;
    
    // Retrieve the Mach port used to initiate communication with I/O Kit
    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult)
    {
        printf("IOMasterPort returned %d\n", kernResult);
        return kernResult;
    }
    
    // Ethernet interfaces are instances of class kIOEthernetInterfaceClass.
    // IOServiceMatching is a convenience function to create a dictionary with the key kIOProviderClassKey and
    // the specified value.
    matchingDict = IOServiceMatching(kIOEthernetInterfaceClass);
	
    // Note that another option here would be:
    // matchingDict = IOBSDMatching("en0");
	
    if (NULL == matchingDict)
    {
        printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else {
        // Each IONetworkInterface object has a Boolean property with the key kIOPrimaryInterface. Only the
        // primary (built-in) interface has this property set to TRUE.
        
        // IOServiceGetMatchingServices uses the default matching criteria defined by IOService. This considers
        // only the following properties plus any family-specific matching in this order of precedence
        // (see IOService::passiveMatch):
        //
        // kIOProviderClassKey (IOServiceMatching)
        // kIONameMatchKey (IOServiceNameMatching)
        // kIOPropertyMatchKey
        // kIOPathMatchKey
        // kIOMatchedServiceCountKey
        // family-specific matching
        // kIOBSDNameKey (IOBSDNameMatching)
        // kIOLocationMatchKey
        
        // The IONetworkingFamily does not define any family-specific matching. This means that in
        // order to have IOServiceGetMatchingServices consider the kIOPrimaryInterface property, we must
        // add that property to a separate dictionary and then add that to our matching dictionary
        // specifying kIOPropertyMatchKey.
		
        propertyMatchDict = CFDictionaryCreateMutable( kCFAllocatorDefault, 0,
													  &kCFTypeDictionaryKeyCallBacks,
													  &kCFTypeDictionaryValueCallBacks);
		
        if (NULL == propertyMatchDict)
        {
            printf("CFDictionaryCreateMutable returned a NULL dictionary.\n");
        }
        else {
            // Set the value in the dictionary of the property with the given key, or add the key
            // to the dictionary if it doesn't exist. This call retains the value object passed in.
            CFDictionarySetValue(propertyMatchDict, CFSTR(kIOPrimaryInterface), kCFBooleanTrue);
            
            // Now add the dictionary containing the matching value for kIOPrimaryInterface to our main
            // matching dictionary. This call will retain propertyMatchDict, so we can release our reference
            // on propertyMatchDict after adding it to matchingDict.
            CFDictionarySetValue(matchingDict, CFSTR(kIOPropertyMatchKey), propertyMatchDict);
            CFRelease(propertyMatchDict);
        }
    }
    
    // IOServiceGetMatchingServices retains the returned iterator, so release the iterator when we're done with it.
    // IOServiceGetMatchingServices also consumes a reference on the matching dictionary so we don't need to release
    // the dictionary explicitly.
    kernResult = IOServiceGetMatchingServices(masterPort, matchingDict, matchingServices);
    if (KERN_SUCCESS != kernResult)
    {
        printf("IOServiceGetMatchingServices returned %d\n", kernResult);
    }
	
    return kernResult;
}

// Given an iterator across a set of Ethernet interfaces, return the MAC address of the last one.
// If no interfaces are found the MAC address is set to an empty string.
// In this sample the iterator should contain just the primary interface.
kern_return_t __GetMACAddress(io_iterator_t intfIterator, UInt8 *MACAddress)
{
    io_object_t    intfService;
    io_object_t    controllerService;
    kern_return_t  kernResult = KERN_FAILURE;
    
    // Initialize the returned address
    bzero(MACAddress, kIOEthernetAddressSize);
    
    // IOIteratorNext retains the returned object, so release it when we're done with it.
    while ((intfService = IOIteratorNext(intfIterator)))
    {
        CFTypeRef  MACAddressAsCFData;
		
        // IONetworkControllers can't be found directly by the IOServiceGetMatchingServices call,
        // since they are hardware nubs and do not participate in driver matching. In other words,
        // registerService() is never called on them. So we've found the IONetworkInterface and will
        // get its parent controller by asking for it specifically.
        
        // IORegistryEntryGetParentEntry retains the returned object, so release it when we're done with it.
        kernResult = IORegistryEntryGetParentEntry( intfService,
												   kIOServicePlane,
												   &controllerService );
		
        if (KERN_SUCCESS != kernResult)
        {
            printf("IORegistryEntryGetParentEntry returned 0x%08x\n", kernResult);
        }
        else {
            // Retrieve the MAC address property from the I/O Registry in the form of a CFData
            MACAddressAsCFData = IORegistryEntryCreateCFProperty( controllerService,
																 CFSTR(kIOMACAddress),
																 kCFAllocatorDefault,
																 0);
            if (MACAddressAsCFData)
            {
                // Get the raw bytes of the MAC address from the CFData
                CFDataGetBytes(MACAddressAsCFData, CFRangeMake(0, kIOEthernetAddressSize), MACAddress);
                CFRelease(MACAddressAsCFData);
            }
			
            // Done with the parent Ethernet controller object so we release it.
            (void) IOObjectRelease(controllerService);
        }
        
        // Done with the Ethernet interface object so we release it.
        (void) IOObjectRelease(intfService);
    }
	
    return kernResult;
}
#endif

@implementation NSBundle (VMFoundation)

+ (NSString*) appVersion
{
    return [[NSBundle mainBundle] appVersion];
}

- (NSString*) appVersion
{
	return [self objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString*) buildVersion
{
    return [[NSBundle mainBundle] buildVersion];
}

- (NSString*) buildVersion
{
	return [self objectForInfoDictionaryKey:@"CFBundleVersion"];
}

+ (NSInteger) systemVersion
{
    static NSInteger systemVersion;
    
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{

#if TARGET_OS_IPHONE
        NSString* s = [[UIDevice currentDevice] systemVersion];
		NSArray* components = [s componentsSeparatedByString:@"."];
		
		for(NSString* c in components)
		{
			NSInteger cv = [c integerValue];
			systemVersion = (systemVersion << 8) | cv;
		}
		if ([components count]== 2) {
			systemVersion = (systemVersion << 8);
		}
#else
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        
        SInt32 versionMajor, versionMinor, versionBugFix;
        if (Gestalt(gestaltSystemVersionMajor, &versionMajor) != noErr) versionMajor = 0;
        if (Gestalt(gestaltSystemVersionMinor, &versionMinor) != noErr)  versionMinor= 0;
        if (Gestalt(gestaltSystemVersionBugFix, &versionBugFix) != noErr) versionBugFix = 0;
        
#pragma clang diagnostic pop
        
        systemVersion = (versionMajor << 16) | (versionMinor << 8) | (versionBugFix);
#endif
    });
    
	return systemVersion;
}

+ (NSString*) systemVersionString
{
#if TARGET_OS_IPHONE
    return [[UIDevice currentDevice] systemVersion];
#else
    NSInteger version = [self systemVersion];
    NSInteger major = version >> 16;
    NSInteger minor = (version >> 8) & 0xff;
    NSInteger bugfix = version & 0xff;
    
    return (bugfix > 0) ? [NSString stringWithFormat:@"%ld.%ld.%ld", major, minor, bugfix] : [NSString stringWithFormat:@"%ld.%ld", major, minor];
#endif
}

+ (NSString*) macAddress
{
#if TARGET_OS_IPHONE
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    NSString            *errorFlag = NULL;
    size_t              length;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    // Get the size of the data available (store in len)
    else if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
        errorFlag = @"sysctl mgmtInfoBase failure";
    // Alloc memory based on above call
    else if ((msgBuffer = malloc(length)) == NULL)
        errorFlag = @"buffer allocation failure";
    // Get system information, store in buffer
    else if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
    {
        free(msgBuffer);
        errorFlag = @"sysctl msgBuffer failure";
    }
    else
    {
        // Map msgbuffer to interface message structure
        struct if_msghdr *interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
        
        // Map to link-level socket structure
        struct sockaddr_dl *socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
        
        // Copy link layer address data in socket structure to an array
        unsigned char macAddress[6];
        memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
        
        // Read from char array into a string object, into traditional Mac address format
        NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                      macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5]];
        DebugLog(@"Mac Address: %@", macAddressString);
        
        // Release the buffer memory
        free(msgBuffer);
        
        return macAddressString;
    }
    
    // Error...
    ErrLog(@"Error: %@", errorFlag);
    
    return errorFlag;

#else
    kern_return_t kernResult = KERN_SUCCESS;
    UInt8 MACAddress [kIOEthernetAddressSize] = {0,0,0,0,0,0};
    
    io_iterator_t intfIterator = 0;
	kernResult = __FindEthernetInterfaces(&intfIterator);
    
    if (KERN_SUCCESS != kernResult)
    {
        printf("FindEthernetInterfaces returned 0x%08x\n", kernResult);
    }
    else {
        kernResult = __GetMACAddress(intfIterator, MACAddress);
        
        if (KERN_SUCCESS != kernResult)
        {
            printf("GetMACAddress returned 0x%08x\n", kernResult);
        }
    }
    
    (void) IOObjectRelease(intfIterator);  // Release the iterator.
	
	//char* mac = "\xc4\x2c\x03\x35\x11\x62";
	//memcpy(MACAddress, mac, kIOEthernetAddressSize);
	
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",MACAddress[0], MACAddress[1], MACAddress[2], MACAddress[3], MACAddress[4], MACAddress[5]];
#endif
}

+ (NSString*) deviceId
{
#if TARGET_OS_IPHONE
    return [[UIDevice currentDevice].identifierForVendor UUIDString];
#else
    NSString* macAddress = [self macAddress];
    NSString* username = NSUserName();
    NSString* devicePermanentId = [[macAddress stringByAppendingString:username] MD5Hash];
    
    devicePermanentId = [devicePermanentId stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
    devicePermanentId = [devicePermanentId stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    devicePermanentId = [devicePermanentId stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    
    return devicePermanentId;
#endif
}

+ (NSString*) deviceName
{
#if TARGET_OS_IPHONE
    return [[UIDevice currentDevice] name];
#else
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, (CFStringRef)@"Vemedio", NULL, NULL);
	CFStringRef computerName = SCDynamicStoreCopyComputerName(store, NULL);
	CFRelease(store);
	store = NULL;
	
	return (__bridge_transfer NSString*)computerName;
#endif
}

+ (NSString *) _getSysInfoByName:(char *)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    return results;
}

+ (NSString*) platform
{
    return [self _getSysInfoByName:"hw.machine"];
}

+ (NSString*) pathToLogsDirectory
{
    NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString* logsPath = [libraryPath stringByAppendingPathComponent:@"Logs"];
    NSFileManager* fman = [[NSFileManager alloc] init];
    
    if (![fman fileExistsAtPath:logsPath]) {
        [fman createDirectoryAtPath:logsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return logsPath;
}

@end
