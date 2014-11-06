//
//  SLImportDataProvider.m
//
//
//  Created by Truong Tong on 11/2/14.
//
//

#import "SLImportDataProvider.h"
#import "DDXMLDocument.h"
#import "DDXMLElement.h"
#import "SLProjectEntities.h"
#import "SLContactEntities.h"
#import "SLSiteEntities.h"
#import "SLMeasurementsEntities.h"
#import "SLSite_ManagementEntities.h"
#import "Project.h"
#import "Contact.h"
#import "Measurements.h"
#import "Site.h"
#import "Site_Management.h"
#import "XMLDefine.h"

@implementation SLImportDataProvider


/*
 * Import data from XML file to core data
 * Only accept XML file
 * Return 
 * 0: import all records fail
 * 1: import all records successfully
 * 2: import some records fail, some record successful
 */
+(int)importDataFromFile:(NSString*)pathOfFile toManagedObjectContext:(NSManagedObjectContext*)context
{
    NSData* data = [NSData dataWithContentsOfFile:pathOfFile];
    NSError* error;
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
    NSArray* elementsProject =[doc nodesForXPath:@"//projects/project" error:nil];
    int iSuccess = 0;
    for (DDXMLElement* node in elementsProject)
    {
        if([self createNewProject:[node children] WithManagedObjectContext:context])
        {
            NSLog(@"Import project successfully.");
            iSuccess++;
        }
        else
        {
            NSLog(@"Import project failure.");
        }
    }
    if(iSuccess == 0)
    {
        return 0;
    }
    else if(iSuccess == elementsProject.count)
    {
        return 1;
    }
    return 2;
}

#pragma -mark Helper method

/*
 * Create a new project with parameters specific for project
 * @param: arrNodes: array of chilren nodes of project from XML file
 * @param: context: object to store data to core data
 * Return new project if created successfully, otherwise return Nil
 */
+(BOOL)createNewProject:(NSArray*)arrNodes WithManagedObjectContext:(NSManagedObjectContext*)context
{
    SLProjectEntities* projectEntities = [[SLProjectEntities alloc] initWithManagedObjectContext:context];
    NSString* customer;
    NSString* name;
    NSString* number;
    NSString* contact;
    Project* project;
    NSMutableArray* createdContacts;
    NSMutableArray* createdSites;
    for (DDXMLNode* itemNode in arrNodes)
    {
        if([itemNode.name isEqualToString:ELEMENT_PROJECT_CUSTOMER])
        {
            customer = itemNode.stringValue;
        }
        else if([itemNode.name isEqualToString:ELEMENT_PROJECT_NAME])
        {
            name = itemNode.stringValue;
        }
        else if([itemNode.name isEqualToString:ELEMENT_PROJECT_NUMBER])
        {
            number = itemNode.stringValue;
            if([projectEntities isProjectExisted:number])
            {
                return TRUE;//Don't proccessing if the project number stored in database
            }
        }
        else if([itemNode.name isEqualToString:ELEMENT_PROJECT_CONTRACT])
        {
            contact = itemNode.stringValue;
        }
        else if([itemNode.name isEqualToString:ELEMENT_PROJECT_ROOT_CONTACTS])//Contacts
        {
            //Save contact to core data
            NSArray* elementsContact = [itemNode nodesForXPath:@"//contacts/contact" error:nil];
            createdContacts = [self addMoreContacts:elementsContact WithManagedObjectContext:context];
        }
        else if([itemNode.name isEqualToString:ELEMENT_PROJECT_ROOT_SITES])//Contacts
        {
            //Save Sites to core data
            NSArray* elementsSites = [itemNode nodesForXPath:@"//sites/site" error:nil];
            createdSites = [self addMoreSites:elementsSites WithManagedObjectContext:context];
        }
    }
    project = [projectEntities createNewProject:customer name:name number:number contact:contact];
    //Add relationship contact
    for (Contact* contact in createdContacts)
    {
        [project addReprojectTocontactObject:contact];
    }
    //Add relationship Site
    for (Site* site in createdSites)
    {
        [project addReprojectTositeObject:site];
    }
    return [project.managedObjectContext save:nil];
}

/*
 * Add contacts to database
 * @param contactsNode: array of contact need to add
 * @param: context: object to store data to core data
 * Return a array created in database
 */
+(NSMutableArray*)addMoreContacts:(NSArray*)contactsNode WithManagedObjectContext:(NSManagedObjectContext*)context
{
    NSMutableArray* createdContacts = [NSMutableArray new];
    SLContactEntities* contactEntities = [[SLContactEntities alloc] initWithManagedObjectContext:context];
    Contact* contact;
    NSString* name;
    NSString* email;
    NSString* telephone;
    for (DDXMLElement* contactElement in contactsNode)
    {
        for (DDXMLElement* item in [contactElement children])
        {
            if([item.name isEqualToString:ELEMENT_CONTACT_NAME])
            {
                name = item.stringValue;
            }
            else if([item.name isEqualToString:ELEMENT_CONTACT_TELEPHONE])
            {
                telephone = item.stringValue;
            }
            else if([item.name isEqualToString:ELEMENT_CONTACT_MAIL])
            {
                email = item.stringValue;
            }
        }
        contact = [contactEntities createContact:email name:name telephone:telephone];
        if(contact)
        {
            [createdContacts addObject:contact];
        }
    }
    
    return createdContacts;
}

/*
 * Add Measurements to database
 * @param measurementsNode: array of Measurement need to add
 * @param: context: object to store data to core data
 * Return a array created in database
 */
+(NSMutableArray*)addMoreMeasurements:(NSArray*)measurementsNode WithManagedObjectContext:(NSManagedObjectContext*)context
{
    NSMutableArray* createdMeasurements = [NSMutableArray new];
    SLMeasurementsEntities* measurementsEntities = [[SLMeasurementsEntities alloc] initWithManagedObjectContext:context];
    Measurements* measurement;
    NSNumber * baseplateDepth;
    NSNumber * baseplateHeight;
    NSNumber * baseplateLenght;
    NSString * baseplatePosition;
    NSNumber * baseplateWidth;
    NSNumber * coverSpec;
    NSNumber * coverType;
    NSNumber * hohe;
    NSString * position;
    for (DDXMLElement* measurementElement in measurementsNode)
    {
        for (DDXMLElement* item in [measurementElement children])
        {
            if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS_MEASUREMENT_POSITION])
            {
                position = item.stringValue;
            }
            else if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS_MEASUREMENT_HEIGTH])
            {
                hohe = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS_MEASUREMENT_COVERSPEC])
            {
               coverSpec = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS_MEASUREMENT_COVERTYPE])
            {
                coverType = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS_MEASUREMENT_BASEPLATEPOSITION])
            {
                baseplatePosition = item.stringValue;
            }
            else if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS_MEASUREMENT_BASEPLATEHEIGHT])
            {
                baseplateHeight = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS_MEASUREMENT_BASEPLATEDEPTH])
            {
                baseplateDepth = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS_MEASUREMENT_BASEPLATEWIDTH])
            {
                baseplateWidth = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS_MEASUREMENT_BASEPLATELENGTH])
            {
                baseplateLenght = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
        }
        measurement = [measurementsEntities createNewMeasurements:coverType coverSpec:coverSpec baseplateHeight:baseplateHeight hohe:hohe baseplateDepth:baseplateDepth position:position baseplatePosition:baseplatePosition baseplateWidth:baseplateWidth baseplateLenght:baseplateLenght];
        if(measurement)
        {
            [createdMeasurements addObject:measurement];
        }
    }
    
    return createdMeasurements;
}

/*
 * Add sites to database
 * @param siteNode: array of site need to add
 * @param: context: object to store data to core data
 * Return a array created in database
 */
+(NSMutableArray*)addMoreSites:(NSArray*)siteNode WithManagedObjectContext:(NSManagedObjectContext*)context
{
    NSMutableArray* createdSites = [NSMutableArray new];
    SLSiteEntities* siteEntities = [[SLSiteEntities alloc] initWithManagedObjectContext:context];
    Site* site;
    Site_Management* siteManagement;
    NSMutableArray* measurementedArr;
    NSString* siteNumber;
    NSString* siteName;
    NSString* siteLocation;
    NSData* siteDrawing;
    NSData* sitePics;
    NSNumber* signType;
    NSNumber* signAlignment;
    NSNumber* signStructureClearance;
    NSNumber* signGroundClearance;
    NSNumber* speedzone;
    NSNumber* blankCover;
    for (DDXMLElement* siteElement in siteNode)
    {
        for (DDXMLElement* item in [siteElement children])
        {
            if([item.name isEqualToString:ELEMENT_SITE_SITENUMBER])
            {
                siteNumber = item.stringValue;
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SITENAME])
            {
                siteName = item.stringValue;
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SITELOCATION])
            {
                siteLocation = item.stringValue;
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SIGNDRAWINGS])
            {
                //Has chilren node
                NSArray* elementsSiteDrawing = [siteElement nodesForXPath:@"//signDrawings/signDrawing" error:nil];
                NSMutableArray* arrSiteDrawing = [NSMutableArray new];
                for (DDXMLElement* item in elementsSiteDrawing)
                {
                    if(item.stringValue)
                    {
                        [arrSiteDrawing addObject:item.stringValue];
                    }
                }
                siteDrawing = [NSKeyedArchiver archivedDataWithRootObject:arrSiteDrawing];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SIGNTYPE])
            {
                signType = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SIGNALIGNMENT])
            {
                signAlignment = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SIGNSTRUCTURECLEARANCE])
            {
                signStructureClearance = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SIGNGROUNDCLEARANCE])
            {
                signGroundClearance = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SPEEDZONE])
            {
                speedzone = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_BLANKCOVER])
            {
                blankCover = [NSNumber numberWithDouble:[item.stringValue doubleValue]];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SITEPICS])
            {
                //Has chilren
                NSArray* elementsSitePics = [siteElement nodesForXPath:@"//sitePics/sitePic" error:nil];
                NSMutableArray* arrSitePic = [NSMutableArray new];
                for (DDXMLElement* item in elementsSitePics)
                {
                    if(item.stringValue)
                    {
                        [arrSitePic addObject:item.stringValue];
                    }
                }
                sitePics = [NSKeyedArchiver archivedDataWithRootObject:arrSitePic];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_MEASUREMENTS])
            {
                //Has chilren
                NSArray* elementsMeasurements = [siteElement nodesForXPath:@"//measurements/measurement" error:nil];
                measurementedArr = [self addMoreMeasurements:elementsMeasurements WithManagedObjectContext:context];
            }
            else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT])
            {
                siteManagement = [self addSiteManagement:[item children] WithManagedObjectContext:context];
                
            }
        }
        site = [siteEntities createNewSite:siteNumber name:siteName signGroundClearance:signGroundClearance blankCover:blankCover signAlignment:signAlignment signStructureClearance:signStructureClearance signDrawing:siteDrawing signType:signType siteLocation:siteLocation sitepic:sitePics speedZone:speedzone measurement:nil];
        //Add relationship to measurements
        for (Measurements* measurements in measurementedArr)
        {
            [site addResiteTomeasurementObject:measurements];
        }
        //Add relationship to site management
        site.reprojectTositemanagement = siteManagement;
        if([site.managedObjectContext save:nil])
        {
            [createdSites addObject:site];
        }
    }
    return createdSites;
}

/*
 * Add Site management to database
 * @param siteManagementNode
 * @param: context: object to store data to core data
 * Return a Site_Management created
 */
+(Site_Management*)addSiteManagement:(NSArray*)siteManagemenstNode WithManagedObjectContext:(NSManagedObjectContext*)context
{
    Site_Management* siteManagement;
    NSString * concern;
    NSData * concernPic;
    NSString * concernSketch;
    NSString * extracost;
    NSData * extracostPic;
    NSString * handicap;
    NSData * handicapPic;
    NSString * handicapSketch;
    NSString * note;
    NSData * notePic;
    NSString * noteSketch;
    NSString * extracostSketch;
    SLSite_ManagementEntities* siteManagementEntities = [[SLSite_ManagementEntities alloc] initWithManagedObjectContext:context];
    for (DDXMLElement* item in siteManagemenstNode)
    {
        if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_NOTE])
        {
            note = item.stringValue;
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_NOTESKETCH])
        {
            noteSketch = item.stringValue;
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_CONCERN])
        {
            concern = item.stringValue;
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_CONCERNSKETCH])
        {
            concernSketch = item.stringValue;
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_CONCERNPICS])
        {
            NSArray* elementsConcerPics = [item nodesForXPath:@"//concernPics/concernPic" error:nil];
            NSMutableArray* arrConcerPic = [NSMutableArray new];
            for (DDXMLElement* item in elementsConcerPics)
            {
                if(item.stringValue)
                {
                    [arrConcerPic addObject:item.stringValue];
                }
            }
            concernPic = [NSKeyedArchiver archivedDataWithRootObject:arrConcerPic];
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_HANDICAP])
        {
            handicap = item.stringValue;
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_HANDISKETCH])
        {
            handicapSketch = item.stringValue;
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_HANDIPICS])
        {
            NSArray* elementshandiPics = [item nodesForXPath:@"//handicapPics/handicapPic" error:nil];
            NSMutableArray* arrhandiPic = [NSMutableArray new];
            for (DDXMLElement* item in elementshandiPics)
            {
                if(item.stringValue)
                {
                    [arrhandiPic addObject:item.stringValue];
                }
            }
            handicapPic = [NSKeyedArchiver archivedDataWithRootObject:arrhandiPic];
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_EXTRACOST])
        {
            extracost = item.stringValue;
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_EXTRASKETCH])
        {
            extracostSketch = item.stringValue ;
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_EXTRACOSTPICS])
        {
            //Has chilren
            NSArray* elementsextraPics = [item nodesForXPath:@"//extracostPics/extracostPic" error:nil];
            NSMutableArray* arrextraPic = [NSMutableArray new];
            for (DDXMLElement* item in elementsextraPics)
            {
                if(item.stringValue)
                {
                    [arrextraPic addObject:item.stringValue];
                }
            }
            extracostPic = [NSKeyedArchiver archivedDataWithRootObject:arrextraPic];
        }
        else if([item.name isEqualToString:ELEMENT_SITE_SITEMANAGEMENT_NOTEPICS])
        {
            //Has chilren
            NSArray* elementNotePics = [item nodesForXPath:@"//notePics/notePic" error:nil];
            NSMutableArray* arrNotePic = [NSMutableArray new];
            for (DDXMLElement* item in elementNotePics)
            {
                if(item.stringValue)
                {
                    [arrNotePic addObject:item.stringValue];
                }
            }
            notePic = [NSKeyedArchiver archivedDataWithRootObject:arrNotePic];
        }
    }
    siteManagement = [siteManagementEntities createSiteManagement:note notePic:notePic noteSketch:noteSketch extracostSketch:extracostSketch handicapSketch:handicapSketch handicapPic:handicapPic handicap:handicap extracostPic:extracostPic extracost:extracost concernSketch:concernSketch concernPic:concernPic concern:concern];
    return siteManagement;
}

@end
