/*
 * Copyright (c) 2012 Photoshot
 *
 * Authors: Micha Mazaheri, Jean-Christophe Lanoë
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

#import <CoreData/CoreData.h>

#pragma mark - PSNotificationBlock Type

/**
 * Block type used to send notifications/messages to a receiver.
 */
typedef void (^PSNotificationBlock)(id receiver);

#pragma mark - PSNotificationFilter Protocol

/**
 * PSNotificationFilter allows to expand the filter concept to any NSObject.
 */
@protocol PSNotificationFilter

/**
 * Returns YES if the message target is equal to the given object as a filtering prospective.
 * If the object and the receiver are not instances of the same class, this method returns NO.
 * @param object The object to compare the receiver with.
 */
- (BOOL)isMatching:(NSObject<PSNotificationFilter>*)object;

@end

#pragma mark - PSNotification Interface

/**
 * PSNotificationCenter is used to send messages to a set of objects conform to a given Objective-C protocol and matching a filter in a many-to-many design.
 */
@interface PSNotificationCenter : NSObject

/**
 * Returns the default instance of PSNotificationCenter.
 */
+ (PSNotificationCenter*)defaultCenter;

/**
 * Sets the object observer as a listener/observer for the target protocol to the target notification center.
 * The observer's class must be conform to the target protocol, this will be checked using +[NSObject conformsToProtocol:].
 * If the observer was already set before for this protocol, this call will just replace the filter.
 * @param observer The target observer. Must not be nil.
 * @param protocol The target protocol. Must not be nil.
 * @param filter The filter. If this parameter is set to nil, the observer will receive messages for any notification sent for this protocol.
 */
- (void)setObserver:(NSObject*)observer protocol:(Protocol *)protocol filter:(NSObject<PSNotificationFilter>*)filter;

/**
 * Sets the object observer as a listener/observer for the target protocol to the default notification center.
 * The observer's class must be conform to the target protocol, this will be checked using +[NSObject conformsToProtocol:].
 * If the observer was already set before for this protocol, this call will just replace the filter.
 * @param observer The target observer. Must not be nil.
 * @param protocol The target protocol. Must not be nil.
 * @param filter The filter. If this parameter is set to nil, the observer will receive messages for any notification sent for this protocol.
 */
+ (void)setObserver:(NSObject*)observer protocol:(Protocol *)protocol filter:(NSObject<PSNotificationFilter>*)filter;

/**
 * Remove the observer from the list of objects observing messages for this protocol to the target notification center.
 * If the observer wasn't registered for the target protocol, this call does nothing.
 * @param observer The target observer. Must not be nil.
 * @param protocol The target protocol. Must not be nil.
 */
- (void)removeObserver:(NSObject*)observer protocol:(Protocol *)protocol;

/**
 * Remove the observer from the list of objects observing messages for this protocol to the default notification center.
 * If the observer wasn't registered for the target protocol, this call does nothing.
 * @param observer The target observer. Must not be nil.
 * @param protocol The target protocol. Must not be nil.
 */
+ (void)removeObserver:(NSObject*)observer protocol:(Protocol *)protocol;

/**
 * Sends a notification/message to any objects having registered to notification for the given protocol and matching the filter using the PSNotificationFilter protocol to the target notification center.
 * The receiver in the block is guaranteed to be conform to the given protocol.
 * The block will be executed on all objects matching the requirements below.
 * @param block The block. A nil block makes the message be ignored.
 * @param protocol The target protocol. Mut not be nil.
 * @param filter The target filter. When nil, the message is broadcasted to all the observers of the protocol.
 */
- (void)send:(PSNotificationBlock)block protocol:(Protocol *)protocol filter:(NSObject<PSNotificationFilter>*)filter;

/**
 * Sends a notification/message to any objects having registered to notification for the given protocol and matching the filter using the PSNotificationFilter protocol to the default notification center.
 * The receiver in the block is guaranteed to be conform to the given protocol.
 * The block will be executed on all objects matching the requirements below.
 * @param block The block 
 * @param protocol The target protocol. Mut not be nil.
 * @param filter The target filter. When nil, the message is broadcasted to all the observers of the protocol.
 */
+ (void)send:(PSNotificationBlock)block protocol:(Protocol *)protocol filter:(NSObject<PSNotificationFilter>*)filter;

@end

#pragma mark - PSNotificationFilter Interfaces

@interface NSString (PSNotificationAdditions) <PSNotificationFilter>
- (BOOL)isMatching:(NSObject<PSNotificationFilter>*)object;
@end

@interface NSArray (PSNotificationAdditions) <PSNotificationFilter>
- (BOOL)isMatching:(NSObject<PSNotificationFilter>*)object;
@end

@interface NSDictionary (PSNotificationAdditions) <PSNotificationFilter>
- (BOOL)isMatching:(NSObject<PSNotificationFilter>*)object;
@end

@interface NSManagedObjectID (PSNotificationAdditions) <PSNotificationFilter>
- (BOOL)isMatching:(NSObject<PSNotificationFilter>*)object;
@end

@interface NSManagedObject (PSNotificationAdditions) <PSNotificationFilter>
- (BOOL)isMatching:(NSObject<PSNotificationFilter>*)object;
@end


