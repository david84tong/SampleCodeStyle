//
//  SLImportDataProvider.h
// 
//
//  Created by Truong Tong on 11/2/14.
//  
//

#import <Foundation/Foundation.h>

@interface SLImportDataProvider : NSObject

/*
 * Import data from XML file to core data
 */
+(int)importDataFromFile:(NSString*)pathOfFile toManagedObjectContext:(NSManagedObjectContext*)context;

@end
