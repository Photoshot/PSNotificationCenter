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

#import "PSNotificationCenter.h"

@interface PSNotificationObservingSpot : NSObject

@property (strong, nonatomic) NSObject<PSNotificationFilter>* filter;
@property (weak, nonatomic) NSObject*observer;

- (BOOL)isRedundantWith:(PSNotificationObservingSpot*)spot;

- (BOOL)isEqual:(id)object;

- (PSNotificationObservingSpot*)findRedundantSpotInArray:(NSArray*)array;

@end

@implementation PSNotificationObservingSpot

@synthesize filter = _filter;
@synthesize observer = _observer;

- (id)initWithObserver:(NSObject*)observer filter:(NSObject<PSNotificationFilter>*)filter
{
	self = [super init];
	if (self) {
		self.observer = observer;
		self.filter = filter;
	}
	return self;
}

- (BOOL)isRedundantWith:(PSNotificationObservingSpot *)spot
{
	return	(self.observer == spot.observer) &&
			(self.filter == nil || spot.filter == nil || [self.filter isMatching:spot.filter]);
}

- (BOOL)isEqual:(id)object
{
	return	[[object class] isSubclassOfClass:[self class]] &&
			(	self.observer == [(PSNotificationObservingSpot*)object observer] &&
				[self.filter isMatching:[(PSNotificationObservingSpot*)object filter]]
			);
}

- (PSNotificationObservingSpot *)findRedundantSpotInArray:(NSArray *)array
{
	for (PSNotificationObservingSpot* spot in array) {
		if ([spot isRedundantWith:self]) {
			return spot;
		}
	}
	return nil;
}

@end

@interface PSNotificationCenter ()

@property (strong, nonatomic) NSMutableDictionary* observers;

@end

@implementation PSNotificationCenter

@synthesize observers = _observers;

#pragma mark - Shared Instance

- (id)init
{
	self = [super init];
	if (self) {
		self.observers = [NSMutableDictionary dictionary];
	}
	return self;
}

+ (PSNotificationCenter*)defaultCenter
{
	static PSNotificationCenter* defaultCenter = nil;
	
	@synchronized ([PSNotificationCenter class]) {
		if (defaultCenter == nil) {
			defaultCenter = [[PSNotificationCenter alloc] init];
		}
	}
	
	return defaultCenter;
}

#pragma mark - Class method / syntax sugar

+ (void)setObserver:(NSObject*)observer protocol:(Protocol *)protocol filter:(NSObject<PSNotificationFilter>*)filter
{
	[[PSNotificationCenter defaultCenter] setObserver:observer protocol:protocol filter:filter];
}

+ (void)removeObserver:(NSObject*)observer protocol:(Protocol *)protocol
{
	[[PSNotificationCenter defaultCenter] removeObserver:observer protocol:protocol];
}

+ (void)send:(PSNotificationBlock)block protocol:(Protocol *)protocol filter:(NSObject<PSNotificationFilter>*)filter
{
	[[PSNotificationCenter defaultCenter] send:block protocol:protocol filter:filter];
}

#pragma mark - Observing

- (void)setObserver:(NSObject*)observer protocol:(Protocol *)protocol filter:(NSObject<PSNotificationFilter>*)filter
{
	NSAssert([[observer class] conformsToProtocol:protocol], @"observer: %@ isn't conform to protocol: %@", observer, NSStringFromProtocol(protocol));
	
	// Get the spots for the given protocol
	NSString* key = NSStringFromProtocol(protocol);
	NSMutableArray* spotsForProtocol = [self.observers objectForKey:key];

	// If no spot array is set for the given protocol, creates a new one
	if (spotsForProtocol == nil) {
		spotsForProtocol = [NSMutableArray arrayWithCapacity:1];
		[self.observers setObject:spotsForProtocol forKey:key];
	}
	
	// Create a new spot for the observer and filter
	PSNotificationObservingSpot* newSpot = [[PSNotificationObservingSpot alloc] initWithObserver:observer filter:filter];

	// Check if the new spot is not redundant (not adding 2 times the same observer for the same protocol and filter)
	PSNotificationObservingSpot* redundantSpot = [newSpot findRedundantSpotInArray:spotsForProtocol];
	if (redundantSpot == nil) {
		// Add the new spot
		[spotsForProtocol addObject:newSpot];
	}
}

- (void)removeObserver:(NSObject*)observer protocol:(Protocol *)protocol
{
	// Get the spots for the given protocol
	NSString* key = NSStringFromProtocol(protocol);
	NSMutableArray* spotsForProtocol = [self.observers objectForKey:key];
	
	// When no spot is found for this protocol, nothing to do
	if (spotsForProtocol == nil) {
		return;
	}
	
	// Removes all the spots for he given observer
	for (PSNotificationObservingSpot* spot in spotsForProtocol) {
		if (spot.observer == observer) {
			[spotsForProtocol removeObject:spot];
		}
	}
}

#pragma mark - Sending

- (void)send:(PSNotificationBlock)block protocol:(Protocol *)protocol filter:(NSObject<PSNotificationFilter>*)filter
{
	// If block is nil, ignore the message
	if (!block) {
		return;
	}
	
	// Get the spots for the given protocol
	NSString* key = NSStringFromProtocol(protocol);
	NSMutableArray* spotsForProtocol = [self.observers objectForKey:key];
	
	// If no spot for the given protocol, ignore the message
	if (spotsForProtocol == nil) {
		return;
	}
	
	// Execute the block on each observer matching the given filter
	for (PSNotificationObservingSpot* spot in spotsForProtocol) {
		if (spot.filter == nil || filter == nil || [spot.filter isMatching:filter]) {
			block(spot.observer);
		}
	}
}

@end

@implementation NSString (PSNotificationAdditions)

- (BOOL)isMatching:(NSString<PSNotificationFilter>*)object
{
	if (![[object class] isSubclassOfClass:[NSString class]]) {
		return NO;
	}
	
	return [self isEqualToString:object];
}

@end

@implementation NSArray (PSNotificationAdditions)

- (BOOL)isMatching:(NSArray<PSNotificationFilter>*)object
{
	if (![[object class] isSubclassOfClass:[NSArray class]]) {
		return NO;
	}
	
	return [self isEqualToArray:object];
}

@end

@implementation NSDictionary (PSNotificationAdditions)

- (BOOL)isMatching:(NSDictionary<PSNotificationFilter>*)object
{
	if (![[object class] isSubclassOfClass:[NSDictionary class]]) {
		return NO;
	}
	
	return [self isEqualToDictionary:object];
}

@end

@implementation NSManagedObjectID (PSNotificationAdditions)

- (BOOL)isMatching:(NSManagedObjectID<PSNotificationFilter>*)object
{
	if (![[object class] isSubclassOfClass:[NSManagedObjectID class]]) {
		return NO;
	}
	
	return [self isEqual:object];
}

@end

@implementation NSManagedObject (PSNotificationAdditions)

- (BOOL)isMatching:(NSManagedObject<PSNotificationFilter>*)object
{
	if (![[object class] isSubclassOfClass:[NSManagedObject class]]) {
		return NO;
	}
	
	return [self isEqual:object];
}

@end
