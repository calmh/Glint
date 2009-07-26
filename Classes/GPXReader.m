//
//  GPXReader.m
//  Glint
//
//  Created by Jakob Borg on 7/25/09.
//  Copyright 2009 Jakob Borg. All rights reserved.
//

#import "GPXReader.h"

@implementation GPXReader

- (void)dealloc {
        [locations release];
        [super dealloc];
}

- (id)initWithFilename:(NSString*)filename
{
        if (self = [self init]) {
                locations = [[NSMutableArray alloc] init];
                lastReadLat = lastReadLon = 0.0;
                lastReadDate = nil;
                currentlyReadingTime = NO;    
                NSData *data = [[NSData alloc] initWithContentsOfFile:filename];
                NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
                [parser setShouldProcessNamespaces:NO];
                [parser setShouldResolveExternalEntities:NO];
                [parser setDelegate:self];
                if (![parser parse]) {
                        NSLog([[parser parserError] description]);
                }
                [parser release];
                [data release];
        }
        return self;
}

- (NSArray*)locations {
        return [NSArray arrayWithArray:locations];
}

/*
 * NSXMLParser delegate stuff
 */

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
        if([elementName isEqualToString:@"time"]) {
                currentlyReadingTime = YES;
        }
        else if([elementName isEqualToString:@"trkpt"]) {
                lastReadLat = [[attributeDict objectForKey:@"lat"] floatValue];
                lastReadLon = [[attributeDict objectForKey:@"lon"] floatValue];
        }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
        if([elementName isEqualToString:@"time"]) {
                currentlyReadingTime = NO;
        }
        else if([elementName isEqualToString:@"trkpt"]) {
                CLLocationCoordinate2D coord;
                coord.latitude = lastReadLat;
                coord.longitude = lastReadLon;
                CLLocation *loc = [[CLLocation alloc] initWithCoordinate:coord altitude:0 horizontalAccuracy:-1 verticalAccuracy:-1 timestamp:lastReadDate];
                [locations addObject:loc];
                [loc release];
                [lastReadDate release];
                lastReadDate = nil;
                lastReadLat = lastReadLon = 0.0;
        }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
        if(currentlyReadingTime) {
                NSDateFormatter *form = [[NSDateFormatter alloc] init];
                [form setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                lastReadDate = [[form dateFromString:string] retain];
        }
}

@end
