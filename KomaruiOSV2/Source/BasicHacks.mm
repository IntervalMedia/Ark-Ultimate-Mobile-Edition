#import "BasicHacks.h"
#import "../MenuLoad/Includes.h"

// Constants for memory offsets - moved to constants for better maintainability
static const uintptr_t kOffsetCustomTimeDilation = 0x234;
static const uintptr_t kOffsetNormalFOV = 0x33c0;
static const uintptr_t kOffsetFreeCamDistance = 0x2bc0;
static const uintptr_t kOffsetDayCycleSpeed = 0xeac;
static const uintptr_t kOffsetNightCycleSpeed = 0xeb0;

static const uintptr_t kOffsetGWorld = 0x04d5b510;
static const uintptr_t kOffsetULevel = 0x1d0;
static const uintptr_t kOffsetOwningGameInstance = 0x320;
static const uintptr_t kOffsetLocalPlayers = 0x38;
static const uintptr_t kOffsetLocalPlayer = 0x0;
static const uintptr_t kOffsetLocalPlayerController = 0x30;
static const uintptr_t kOffsetAPawn = 0x408;
static const uintptr_t kOffsetPlayerCameraManager = 0x480;
static const uintptr_t kOffsetWorldSettings = 0x258;

// Error domain for BasicHacks errors
static NSString * const kBasicHacksErrorDomain = @"BasicHacksErrorDomain";

typedef NS_ERROR_ENUM(kBasicHacksErrorDomain, BasicHacksError) {
    BasicHacksErrorInvalidPointer = 1000,
    BasicHacksErrorMemoryAccess = 1001,
    BasicHacksErrorInitialization = 1002,
    BasicHacksErrorPointerChainResolution = 1003
};

// Logging category
static os_log_t basicHacksLog(void) {
    static os_log_t log;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        log = os_log_create("com.arkultimate.mobile", "BasicHacks");
    });
    return log;
}

#pragma mark - GameMemoryManager Implementation

@implementation GameMemoryManager {
    uintptr_t _cachedBaseAddress;
    dispatch_queue_t _memoryQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cachedBaseAddress = 0;
        _memoryQueue = dispatch_queue_create("com.arkultimate.memory", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (BOOL)isValidPointer:(uintptr_t)pointer {
    // More robust pointer validation
    if (pointer == 0 || pointer == (uintptr_t)-1) {
        return NO;
    }
    
    // Check if pointer is in valid memory range for iOS
    if (pointer < 0x100000000 || pointer >= 0x3000000000) {
        return NO;
    }
    
    // Additional validation could be added here (e.g., page alignment, accessibility)
    return YES;
}

- (BOOL)readFloatAtAddress:(uintptr_t)address value:(float *)outValue error:(NSError **)error {
    if (![self isValidPointer:address]) {
        if (error) {
            *error = [NSError errorWithDomain:kBasicHacksErrorDomain
                                         code:BasicHacksErrorInvalidPointer
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid memory address for read operation"}];
        }
        os_log_error(basicHacksLog(), "Attempted to read from invalid address: 0x%lx", address);
        return NO;
    }
    
    @try {
        *outValue = *(float *)address;
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:kBasicHacksErrorDomain
                                         code:BasicHacksErrorMemoryAccess
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Memory access exception: %@", exception.reason]}];
        }
        os_log_error(basicHacksLog(), "Memory access exception during read: %@", exception.reason);
        return NO;
    }
}

- (BOOL)writeFloat:(float)value toAddress:(uintptr_t)address error:(NSError **)error {
    if (![self isValidPointer:address]) {
        if (error) {
            *error = [NSError errorWithDomain:kBasicHacksErrorDomain
                                         code:BasicHacksErrorInvalidPointer
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid memory address for write operation"}];
        }
        os_log_error(basicHacksLog(), "Attempted to write to invalid address: 0x%lx", address);
        return NO;
    }
    
    @try {
        *(float *)address = value;
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:kBasicHacksErrorDomain
                                         code:BasicHacksErrorMemoryAccess
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Memory access exception: %@", exception.reason]}];
        }
        os_log_error(basicHacksLog(), "Memory access exception during write: %@", exception.reason);
        return NO;
    }
}

- (uintptr_t)getBaseAddress {
    if (_cachedBaseAddress != 0) {
        return _cachedBaseAddress;
    }
    
    // Cache the base address for efficiency
    _cachedBaseAddress = (uintptr_t)_dyld_get_image_header(0);
    os_log_info(basicHacksLog(), "Cached base address: 0x%lx", _cachedBaseAddress);
    return _cachedBaseAddress;
}

- (uintptr_t)resolvePointerChain:(uintptr_t)baseAddress offsets:(NSArray<NSNumber *> *)offsets error:(NSError **)error {
    uintptr_t currentAddress = baseAddress;
    
    for (NSNumber *offsetNumber in offsets) {
        uintptr_t offset = [offsetNumber unsignedLongValue];
        currentAddress += offset;
        
        if (![self isValidPointer:currentAddress]) {
            if (error) {
                *error = [NSError errorWithDomain:kBasicHacksErrorDomain
                                             code:BasicHacksErrorPointerChainResolution
                                         userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid pointer in chain at offset 0x%lx", offset]}];
            }
            os_log_error(basicHacksLog(), "Pointer chain resolution failed at offset 0x%lx", offset);
            return 0;
        }
        
        // Dereference if not the last offset
        if (offsetNumber != offsets.lastObject) {
            currentAddress = *(uintptr_t *)currentAddress;
        }
    }
    
    return currentAddress;
}

@end

#pragma mark - HackUpdateManager Implementation

@implementation HackUpdateManager {
    GameMemoryManager *_memoryManager;
    dispatch_queue_t _updateQueue;
}

- (instancetype)initWithMemoryManager:(GameMemoryManager *)memoryManager {
    self = [super init];
    if (self) {
        _memoryManager = memoryManager;
        _updateQueue = dispatch_queue_create("com.arkultimate.updates", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)updateHackValuesWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    dispatch_async(_updateQueue, ^{
        NSError *error = nil;
        BOOL success = [self performUpdateWithError:&error];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, error);
            });
        }
    });
}

- (BOOL)performUpdateWithError:(NSError **)error {
    // Get base address
    uintptr_t baseAddr = [_memoryManager getBaseAddress];
    if (![_memoryManager isValidPointer:baseAddr]) {
        if (error) {
            *error = [NSError errorWithDomain:kBasicHacksErrorDomain
                                         code:BasicHacksErrorInvalidPointer
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid base address"}];
        }
        return NO;
    }
    
    // Resolve pointer chains safely
    NSError *chainError = nil;
    
    // GWorld chain
    uintptr_t gWorldAddr = [_memoryManager resolvePointerChain:baseAddr
                                                       offsets:@[@(kOffsetGWorld)]
                                                         error:&chainError];
    if (chainError) {
        if (error) *error = chainError;
        return NO;
    }
    
    uintptr_t gWorld = *(uintptr_t *)gWorldAddr;
    if (![_memoryManager isValidPointer:gWorld]) {
        if (error) {
            *error = [NSError errorWithDomain:kBasicHacksErrorDomain
                                         code:BasicHacksErrorInvalidPointer
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid GWorld pointer"}];
        }
        return NO;
    }
    
    // Continue with the rest of the pointer chain resolution
    uintptr_t uLevel = *(uintptr_t *)(gWorld + kOffsetULevel);
    if (![_memoryManager isValidPointer:uLevel]) return NO;
    
    uintptr_t owningGameInstance = *(uintptr_t *)(gWorld + kOffsetOwningGameInstance);
    if (![_memoryManager isValidPointer:owningGameInstance]) return NO;
    
    uintptr_t localPlayers = *(uintptr_t *)(owningGameInstance + kOffsetLocalPlayers);
    if (![_memoryManager isValidPointer:localPlayers]) return NO;
    
    uintptr_t localPlayer = *(uintptr_t *)(localPlayers + kOffsetLocalPlayer);
    if (![_memoryManager isValidPointer:localPlayer]) return NO;
    
    uintptr_t localPlayerController = *(uintptr_t *)(localPlayer + kOffsetLocalPlayerController);
    if (![_memoryManager isValidPointer:localPlayerController]) return NO;
    
    uintptr_t aPawn = *(uintptr_t *)(localPlayerController + kOffsetAPawn);
    if (![_memoryManager isValidPointer:aPawn]) return NO;
    
    uintptr_t playerCameraManager = *(uintptr_t *)(localPlayerController + kOffsetPlayerCameraManager);
    if (![_memoryManager isValidPointer:playerCameraManager]) return NO;
    
    uintptr_t worldSettings = *(uintptr_t *)(uLevel + kOffsetWorldSettings);
    if (![_memoryManager isValidPointer:worldSettings]) return NO;
    
    // Perform safe memory writes
    BOOL allUpdatesSuccessful = YES;
    
    allUpdatesSuccessful &= [_memoryManager writeFloat:Variables.LocalSpeed
                                             toAddress:(aPawn + kOffsetCustomTimeDilation)
                                                 error:nil];
    
    allUpdatesSuccessful &= [_memoryManager writeFloat:Variables.FOV
                                             toAddress:(playerCameraManager + kOffsetNormalFOV)
                                                 error:nil];
    
    allUpdatesSuccessful &= [_memoryManager writeFloat:Variables.Zoom
                                             toAddress:(playerCameraManager + kOffsetFreeCamDistance)
                                                 error:nil];
    
    allUpdatesSuccessful &= [_memoryManager writeFloat:Variables.DayCycleSpeed
                                             toAddress:(worldSettings + kOffsetDayCycleSpeed)
                                                 error:nil];
    
    allUpdatesSuccessful &= [_memoryManager writeFloat:Variables.NightCycleSpeed
                                             toAddress:(worldSettings + kOffsetNightCycleSpeed)
                                                 error:nil];
    
    if (allUpdatesSuccessful) {
        os_log_debug(basicHacksLog(), "All hack values updated successfully");
    } else {
        os_log_error(basicHacksLog(), "Some hack value updates failed");
    }
    
    return allUpdatesSuccessful;
}

@end

#pragma mark - BasicHacks Implementation

@implementation BasicHacks {
    dispatch_source_t _updateTimer;
    dispatch_queue_t _timerQueue;
    BOOL _isRunning;
}

+ (instancetype)sharedInstance {
    static BasicHacks *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BasicHacks alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _memoryManager = [[GameMemoryManager alloc] init];
        _updateManager = [[HackUpdateManager alloc] initWithMemoryManager:_memoryManager];
        _timerQueue = dispatch_queue_create("com.arkultimate.timer", DISPATCH_QUEUE_SERIAL);
        _isRunning = NO;
        
        os_log_info(basicHacksLog(), "BasicHacks instance initialized");
    }
    return self;
}

- (void)initializeWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Perform initialization checks
        uintptr_t baseAddr = [self.memoryManager getBaseAddress];
        BOOL success = [self.memoryManager isValidPointer:baseAddr];
        NSError *error = nil;
        
        if (!success) {
            error = [NSError errorWithDomain:kBasicHacksErrorDomain
                                        code:BasicHacksErrorInitialization
                                    userInfo:@{NSLocalizedDescriptionKey: @"Failed to initialize: invalid base address"}];
            os_log_error(basicHacksLog(), "Initialization failed: invalid base address");
        } else {
            os_log_info(basicHacksLog(), "BasicHacks initialized successfully");
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, error);
            });
        }
    });
}

- (void)startUpdatesWithInterval:(NSTimeInterval)updateInterval {
    if (_isRunning) {
        os_log_info(basicHacksLog(), "Updates already running");
        return;
    }
    
    // Create a dispatch source timer for efficient, energy-friendly updates
    _updateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _timerQueue);
    
    // Set timer to fire every updateInterval seconds
    uint64_t interval = (uint64_t)(updateInterval * NSEC_PER_SEC);
    uint64_t leeway = interval / 10; // 10% leeway for system optimization
    
    dispatch_source_set_timer(_updateTimer, 
                             dispatch_time(DISPATCH_TIME_NOW, interval),
                             interval,
                             leeway);
    
    // Set the timer event handler
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_updateTimer, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.updateManager updateHackValuesWithCompletion:^(BOOL success, NSError * _Nullable error) {
                if (!success && error) {
                    os_log_error(basicHacksLog(), "Update failed: %@", error.localizedDescription);
                }
            }];
        }
    });
    
    // Start the timer
    dispatch_resume(_updateTimer);
    _isRunning = YES;
    
    os_log_info(basicHacksLog(), "Started updates with interval: %.3f seconds", updateInterval);
}

- (void)stopUpdates {
    if (!_isRunning || !_updateTimer) {
        return;
    }
    
    dispatch_source_cancel(_updateTimer);
    _updateTimer = nil;
    _isRunning = NO;
    
    os_log_info(basicHacksLog(), "Stopped updates");
}

- (BOOL)isRunning {
    return _isRunning;
}

- (void)dealloc {
    [self stopUpdates];
}

@end

#pragma mark - Legacy C++ Compatibility Bridge

// Provide backwards compatibility for existing code
bool BasicHacks_IsValidPointer(long offset) {
    return [[BasicHacks sharedInstance].memoryManager isValidPointer:(uintptr_t)offset];
}

void BasicHacks_Initialize() {
    [[BasicHacks sharedInstance] initializeWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [[BasicHacks sharedInstance] startUpdatesWithInterval:0.1]; // 100ms updates like original
        } else {
            os_log_error(basicHacksLog(), "Legacy initialization failed: %@", error.localizedDescription);
        }
    }];
}