#pragma once

#import <Foundation/Foundation.h>
#import <os/log.h>

// Forward declarations for better modularity
@class GameMemoryManager;
@class HackUpdateManager;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Modernized BasicHacks implementation following iOS best practices
 * 
 * This class provides a safe, efficient way to manage game memory modifications
 * using modern Objective-C patterns, proper error handling, and efficient
 * update mechanisms instead of infinite loops.
 */
@interface BasicHacks : NSObject

+ (instancetype)sharedInstance;
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief Initialize the hack system with proper error handling
 * @param completion Block called when initialization completes
 */
- (void)initializeWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/**
 * @brief Start the hack update system
 * @param updateInterval Time interval between updates (default: 0.1 seconds)
 */
- (void)startUpdatesWithInterval:(NSTimeInterval)updateInterval;

/**
 * @brief Stop the hack update system
 */
- (void)stopUpdates;

/**
 * @brief Check if the hack system is currently running
 */
@property (nonatomic, readonly) BOOL isRunning;

/**
 * @brief Memory manager for safe pointer operations
 */
@property (nonatomic, strong, readonly) GameMemoryManager *memoryManager;

/**
 * @brief Update manager for efficient value updates
 */
@property (nonatomic, strong, readonly) HackUpdateManager *updateManager;

@end

/**
 * @brief Safe memory management abstraction
 */
@interface GameMemoryManager : NSObject

/**
 * @brief Safely validate a memory pointer
 * @param pointer The pointer to validate
 * @return YES if the pointer is valid, NO otherwise
 */
- (BOOL)isValidPointer:(uintptr_t)pointer;

/**
 * @brief Safely read a float value from memory
 * @param address Memory address to read from
 * @param outValue Pointer to store the read value
 * @param error Error information if the operation fails
 * @return YES if successful, NO otherwise
 */
- (BOOL)readFloatAtAddress:(uintptr_t)address value:(float *)outValue error:(NSError **)error;

/**
 * @brief Safely write a float value to memory
 * @param address Memory address to write to
 * @param value Value to write
 * @param error Error information if the operation fails
 * @return YES if successful, NO otherwise
 */
- (BOOL)writeFloat:(float)value toAddress:(uintptr_t)address error:(NSError **)error;

/**
 * @brief Get base address with caching
 */
- (uintptr_t)getBaseAddress;

/**
 * @brief Resolve pointer chain safely
 * @param baseAddress Starting address
 * @param offsets Array of NSNumber offsets
 * @param error Error information if resolution fails
 * @return Final resolved address, or 0 if failed
 */
- (uintptr_t)resolvePointerChain:(uintptr_t)baseAddress offsets:(NSArray<NSNumber *> *)offsets error:(NSError **)error;

@end

/**
 * @brief Efficient update management using modern iOS patterns
 */
@interface HackUpdateManager : NSObject

/**
 * @brief Initialize with memory manager
 */
- (instancetype)initWithMemoryManager:(GameMemoryManager *)memoryManager;

/**
 * @brief Update all hack values efficiently
 * @param completion Block called when update completes
 */
- (void)updateHackValuesWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

// Legacy compatibility - maintain singleton pattern for existing code
static inline BasicHacks* GetBasicHacksInstance(void) {
    return [BasicHacks sharedInstance];
}

#define BasicCheats GetBasicHacksInstance()

// Legacy C++ function compatibility
#ifdef __cplusplus
extern "C" {
#endif

bool BasicHacks_IsValidPointer(long offset);
void BasicHacks_Initialize(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
