//
//  SLImportDataProviderTest.m
// 
//
//  Created by Truong Tong on 11/3/14.
//  
//

#import <XCTest/XCTest.h>
#import "SLImportDataProvider.h"
#import "SLUnitTestHelper.h"
#import "Project.h"
#import "Site.h"
#import "Site_Management.h"
#import "SLProjectEntities.h"

@interface SLImportDataProviderTest : XCTestCase

@property (nonatomic,retain) NSManagedObjectContext *mockObject;

@end

@implementation SLImportDataProviderTest

- (void)setUp
{
    [super setUp];
    self.mockObject = [SLUnitTestHelper mockManagedObjectContext];
}

- (void)tearDown
{
    [super tearDown];
    self.mockObject = nil;
}

- (void)testImportDataSuccess
{
    NSString* pathOfImportFile = [[NSBundle mainBundle] pathForResource:@"signloc_03" ofType:@"xml"];
    int iSuccess = [SLImportDataProvider importDataFromFile:pathOfImportFile toManagedObjectContext:_mockObject];
    XCTAssertEqual(iSuccess, 1, @"Import to database successfully");
    //Check number of object Imported correct
    SLProjectEntities* projectEntities = [[SLProjectEntities alloc] initWithManagedObjectContext:_mockObject];
    Project* projectAdded = [[projectEntities fetchProjects:@"Projektnummer"] lastObject];
    XCTAssertNotNil(projectAdded, @"Passed");
    XCTAssertEqualObjects(projectAdded.customer, @"Kundennummer",@"Passed");
    XCTAssertEqualObjects(projectAdded.name, @"Projektname",@"Passed");
    XCTAssertEqualObjects(projectAdded.number, @"Projektnummer",@"Passed");
    XCTAssertEqualObjects(projectAdded.contact, @"Contract",@"Passed");
    //Contact
    NSArray* contactsAdded = [[projectAdded valueForKey:@"reprojectTocontact"] allObjects];
    XCTAssertEqual((int)contactsAdded.count, 2, @"Passed");
    NSArray* sitesAdded = [[projectAdded valueForKey:@"reprojectTosite"] allObjects];
    XCTAssertEqual((int)sitesAdded.count, 1, @"Passed");
    //Site
    Site* site = sitesAdded[0];
    XCTAssertEqualObjects(site.siteNumber, @"Standortnummer",@"Passed");
    XCTAssertEqualObjects(site.siteName, @"Standortname",@"Passed");
    XCTAssertEqualObjects(site.siteLocation, @"latitude,longitude",@"Passed");
    NSArray* signDrawing = [NSKeyedUnarchiver unarchiveObjectWithData:site.signDrawing];
    XCTAssertEqual((int)signDrawing.count, 4, @"Passed");
    XCTAssertEqualObjects(signDrawing[3], @"./Site/%siteNumber%/Drawings/04.png",@"Passed");
    NSArray* signPic = [NSKeyedUnarchiver unarchiveObjectWithData:site.sitePic];
    XCTAssertEqual((int)signPic.count, 3, @"Passed");
    XCTAssertEqualObjects(signPic[2], @"./%projectNumber%/Sites/%siteNumber%/Pictures/03.png",@"Passed");
    //Measurements
    NSArray* measurementsAdded = [[site valueForKey:@"resiteTomeasurement"] allObjects];
    XCTAssertEqual((int)measurementsAdded.count, 3, @"Passed");
    //Site management
    Site_Management* siteManagementAdded = [site valueForKey:@"reprojectTositemanagement"];
    XCTAssertNotNil(siteManagementAdded, @"Passed");
    NSArray* notePic = [NSKeyedUnarchiver unarchiveObjectWithData:siteManagementAdded.notePic];
    XCTAssertEqual((int)notePic.count, 3, @"Passed");
    XCTAssertEqualObjects(notePic[2], @"./%projectNumber%/Sites/%siteNumber%/siteManagement/notePic/03.png",@"Passed");
    
}

- (void)testImportData_WrongPathFile_Failure
{
    NSString* pathOfImportFile = [[NSBundle mainBundle] pathForResource:@"signloc_044" ofType:@"xml"];
    int iSuccess = [SLImportDataProvider importDataFromFile:pathOfImportFile toManagedObjectContext:_mockObject];
    XCTAssertEqual(iSuccess, 0, @"Import to database failure");
}

@end
