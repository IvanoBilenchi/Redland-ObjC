//
//  RedlandQuery.m
//  Redland Objective-C Bindings
//  $Id: RedlandQuery.m 4 2004-09-25 15:49:17Z kianga $
//
//  Copyright 2004 Rene Puls <http://purl.org/net/kianga/>
//	Copyright 2012 Pascal Pfiffner <http://www.chip.org/>
//  Copyright 2016 Ivano Bilenchi <http://ivanobilenchi.com/>
//
//  This file is available under the following three licenses:
//   1. GNU Lesser General Public License (LGPL), version 2.1
//   2. GNU General Public License (GPL), version 2
//   3. Apache License, version 2.0
//
//  You may not use this file except in compliance with at least one of
//  the above three licenses. See LICENSE.txt at the top of this package
//  for the complete terms and further details.
//
//  The most recent version of this software can be found here:
//  <https://github.com/p2/Redland-ObjC>
//
//  For information about the Redland RDF Application Framework, including
//  the most recent version, see <http://librdf.org/>.
//

#import "RedlandQuery.h"
#import "RedlandWorld.h"
#import "RedlandURI.h"
#import "RedlandQueryResults.h"
#import "RedlandModel.h"
#import "RedlandError.h"

NSString * const RedlandRDQLLanguageName = @"rdql";
NSString * const RedlandSPARQLLanguageName = @"sparql";

@implementation RedlandQuery

@dynamic limit, offset;


#pragma mark - Init and Cleanup
/**
 *  Returns an autoreleased RedlandQuery initialized using initWithLanguageName:queryString:.
 *  @param langName The only supported language name is currently the constant `RedlandSPARQLLanguageName`
 *  @param queryString The query string in the given language
 *  @param baseURI The base URI to use
 *  @param error Error out parameter
 */
+ (id)queryWithLanguageName:(NSString *)langName queryString:(NSString *)queryString baseURI:(RedlandURI *)baseURI error:(NSError *__autoreleasing *)error
{
	return [[self alloc] initWithLanguageName:langName queryString:queryString baseURI:baseURI error:error];
}

/**
 *  Returns an autoreleased RedlandQuery initialized using initWithLanguageName:languageURI:queryString:.
 *  @param langName The only supported language name is currently the constant `RedlandSPARQLLanguageName`
 *  @param langURI The URI identifying the requested query language
 *  @param queryString The query string in the given language
 *  @param baseURI The base uri to use
 *  @param error Error out parameter
 */
+ (id)queryWithLanguageName:(NSString *)langName languageURI:(RedlandURI *)langURI queryString:(NSString *)queryString baseURI:(RedlandURI *)baseURI error:(NSError *__autoreleasing *)error
{
	return [[self alloc] initWithLanguageName:langName languageURI:langURI queryString:queryString baseURI:baseURI error:error];
}

/**
 *  Initializes a RedlandQuery with the given language name and query string.
 *  @param langName The only supported language name is currently the constant `RedlandSPARQLLanguageName`
 *  @param queryString The query string in the given language
 *  @param baseURI The base URI to use
 *  @param error Error out parameter
 */
- (id)initWithLanguageName:(NSString *)langName queryString:(NSString *)queryString baseURI:(RedlandURI *)baseURI error:(NSError *__autoreleasing *)error
{
	return [self initWithLanguageName:langName languageURI:nil queryString:queryString baseURI:baseURI error:error];
}

/**
 *  Initializes a RedlandQuery with the given language name or URI and query string.
 *  @param langName The only supported language name is currently the constant `RedlandSPARQLLanguageName`
 *  @param langURI The URI identifying the requested query language
 *  @param queryString The query string in the given language
 *  @param baseURI The base uri to use
 *  @param error Error out parameter
 */
- (id)initWithLanguageName:(NSString *)langName languageURI:(RedlandURI *)langURI queryString:(NSString *)queryString baseURI:(RedlandURI *)baseURI error:(NSError *__autoreleasing *)error
{
	NSParameterAssert(langName != nil || langURI != nil);
	NSParameterAssert(queryString != nil);
    
    NSError *localError = nil;
	
	librdf_query *newQuery = librdf_new_query([RedlandWorld defaultWrappedWorld],
											  [langName UTF8String],
											  [langURI wrappedURI],
											  (unsigned char *)[queryString UTF8String],
											  [baseURI wrappedURI]);
	if (NULL == newQuery) {
        localError = [NSError redlandWrapperErrorWithCode:RedlandWrapperErrorCodeGeneric
                                     localizedDescription:@"librdf_new_query failed"
                                                 userInfo:@{ @"query": queryString, @"language": (langName ? langName : langURI) }];
        goto err;
	}
    
    localError = [[RedlandWorld defaultWorld] cumulativeError];
    if (localError) {
        goto err;
    }
    
err:
    if (error) {
        *error = localError;
    }
	
    return localError ? nil : [self initWithWrappedObject:newQuery];
}

- (void)dealloc
{
	if (isWrappedObjectOwner) {
		librdf_free_query(wrappedObject);
	}
}

/**
 *  Returns the underlying librdf_query object of the receiver.
 */
- (librdf_query *)wrappedQuery
{
	return wrappedObject;
}



#pragma mark - Query Execution
/**
 *  Run the query on the given model.
 *  @param aModel The model against which to execute the query
 *  @param error Error out parameter
 *  @return A RedlandQueryResults object
 */
- (RedlandQueryResults *)executeOnModel:(RedlandModel *)aModel error:(NSError *__autoreleasing *)error
{
	NSParameterAssert(aModel != nil);
	
	librdf_query_results *results = librdf_query_execute(wrappedObject, [aModel wrappedModel]);
    
    NSError *localError = [[RedlandWorld defaultWorld] cumulativeError];
    
    if (error) {
        *error = localError;
    }
    
    return localError ? nil : [[RedlandQueryResults alloc] initWithWrappedObject:results];
}



#pragma mark - KVC
/**
 *  This is the limit given in the query on the number of results allowed.
 *
 *  The limit is >= 0 if a limit is given, otherwise < 0.
 */
- (int)limit
{
	return librdf_query_get_limit(wrappedObject);
}

- (void)setLimit:(int)newLimit
{
	librdf_query_set_limit(wrappedObject, newLimit);
}

/**
 *  This is the offset given in the query on the number of results allowed.
 *
 *  The offset is >= 0 if an offset is given, otherwise < 0.
 */
- (int)offset
{
	return librdf_query_get_offset(wrappedObject);
}

- (void)setOffset:(int)newOffset
{
	librdf_query_set_offset(wrappedObject, newOffset);
}


@end
