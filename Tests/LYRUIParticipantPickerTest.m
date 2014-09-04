//
//  LYRUIParticipantPickerTest.m
//  LayerSample
//
//  Created by Kevin Coleman on 9/2/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KIFTestCase.h"
#import <KIF/KIF.h>
#import <OCMock/OCMock.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import "KIFSystemTestActor+ViewControllerActions.h"
#import "KIFUITestActor+LSAdditions.h"
#import "LYRCountdownLatch.h"
#import "LSApplicationController.h"
#import "LSAppDelegate.h"
#import "LYRUIParticipantPickerController.h"
#import "LSUIParticipantPickerDataSource.h"
#import "LYRUITestUser.h"
#import "LYRCountDownLatch.h"
#import "LYRUITestInterface.h"
#import "LYRUIParticipantTableViewCell.h"
#import "LYRUITestParticipantCell.h"

@interface LYRUIParticipantPickerTest : XCTestCase

@property (nonatomic, strong) LYRUITestInterface *testInterface;

@end

@implementation LYRUIParticipantPickerTest

- (void)setUp
{
    [super setUp];
    
    LSApplicationController *applicationController =  [(LSAppDelegate *)[[UIApplication sharedApplication] delegate] applicationController];
    
    self.testInterface = [LYRUITestInterface testInterfaceWithApplicationController:applicationController];
    
    LSUser *user = [LYRUITestUser testUserWithNumber:1];
    [self.testInterface registerUser:user];
    [self.testInterface authenticateWithEmail:user.email password:user.password];
    [self.testInterface loadContacts];
    [tester waitForTimeInterval:1];
}

- (void)tearDown
{
    [self.testInterface deleteContacts];
    [self.testInterface logout];
    
    self.testInterface = nil;
    
    [super tearDown];
}

//Load a list of contacts from a local mock server, see them present in the UI. (Verify loading spinner?)
- (void)testToVerifyListOfContactsDisplaysAppropriately
{
    NSSet *participants = [self.testInterface fetchContacts];
    
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        for (LSUser *user in participants) {
            [tester waitForViewWithAccessibilityLabel:[NSString stringWithFormat:@"%@", user.fullName]];
        }
    }];
}

//Search for a participant with a known name and verify that it appears.
- (void)testToVerifySearchForKnownParticipantDisplaysIntendedResult
{
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        NSString *searchText = @"Kevin Coleman";
        [tester tapViewWithAccessibilityLabel:@"Search Bar"];
        [tester enterText:searchText intoViewWithAccessibilityLabel:@"Search Bar"];
        [tester waitForViewWithAccessibilityLabel:searchText];
    }];
}

//Search for a participant with an unknown name and verify that the list is empty.
- (void)testToVerifYSearchForUnknownParticipantDoesNotDisplayResult
{
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        NSString *searchText = @"Fake Name";
        [tester tapViewWithAccessibilityLabel:@"Search Bar"];
        [tester enterText:searchText intoViewWithAccessibilityLabel:@"Search Bar"];
        [tester waitForAbsenceOfViewWithAccessibilityLabel:searchText];
    }];
}

//Configure the picker in single selection mode and verify that it only permits a single selection to be made.
- (void)testToVerifySingleSelectionModeAllowsOnlyOneSelectionAtATime
{
    [self.testInterface logout];
    
    LSUser *user1 = [LYRUITestUser testUserWithNumber:1];
    LSUser *user2 = [LYRUITestUser testUserWithNumber:2];
    
    [self.testInterface registerUser:user2];
    [self.testInterface authenticateWithEmail:user2.email password:user2.password];
    [self.testInterface loadContacts];
    [tester waitForTimeInterval:1];
    
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    controller.allowsMultipleSelection = NO;
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        [tester tapViewWithAccessibilityLabel:user1.fullName];
        [tester waitForViewWithAccessibilityLabel:[self selectionIndicatoraccessibilityLabelForUser:user1]];
        [tester tapViewWithAccessibilityLabel:user2.fullName];
        [tester waitForViewWithAccessibilityLabel:[self selectionIndicatoraccessibilityLabelForUser:user2]];
        [tester waitForAbsenceOfViewWithAccessibilityLabel:[self selectionIndicatoraccessibilityLabelForUser:user1]];
    }];
}

//Configure the picker in multi-selection mode and verify that it allows multiple selections to be made.
- (void)testToVerifyThatMutltiSelectionModeAllowsMultipleParticipantsToBeSelected
{
    [self.testInterface logout];
    
    LSUser *user1 = [LYRUITestUser testUserWithNumber:1];
    LSUser *user2 = [LYRUITestUser testUserWithNumber:2];
    
    [self.testInterface registerUser:user2];
    [self.testInterface authenticateWithEmail:user2.email password:user2.password];
    [self.testInterface loadContacts];
    [tester waitForTimeInterval:1];
    
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    controller.allowsMultipleSelection = YES;
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        [tester tapViewWithAccessibilityLabel:user1.fullName];
        [tester waitForViewWithAccessibilityLabel:[self selectionIndicatoraccessibilityLabelForUser:user1]];
        [tester tapViewWithAccessibilityLabel:user2.fullName];
        [tester waitForViewWithAccessibilityLabel:[self selectionIndicatoraccessibilityLabelForUser:user2]];
        [tester waitForViewWithAccessibilityLabel:[self selectionIndicatoraccessibilityLabelForUser:user1]];
    }];
}

//Verify that tapping a participant once adds a check mark.
- (void)testToVerifyTappingOnParticipantDisplaysACheckmark
{
    [self.testInterface logout];
    
    LSUser *user1 = [LYRUITestUser testUserWithNumber:1];
    LSUser *user2 = [LYRUITestUser testUserWithNumber:2];
    
    [self.testInterface registerUser:user2];
    [self.testInterface authenticateWithEmail:user2.email password:user2.password];
    [self.testInterface loadContacts];
    [tester waitForTimeInterval:1];
    
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        [tester tapViewWithAccessibilityLabel:user1.fullName];
        [tester waitForViewWithAccessibilityLabel:[self selectionIndicatoraccessibilityLabelForUser:user1]];
    }];
}

//Verify that tapping a participant a second time remove the existing check mark.

- (void)testToVerifyTappingOnAParticipantTwiceRemovesCheckmark
{
    [self.testInterface logout];
    
    LSUser *user1 = [LYRUITestUser testUserWithNumber:1];
    LSUser *user2 = [LYRUITestUser testUserWithNumber:2];
    
    [self.testInterface registerUser:user2];
    [self.testInterface authenticateWithEmail:user2.email password:user2.password];
    [self.testInterface loadContacts];
    [tester waitForTimeInterval:1];
    
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        [tester tapViewWithAccessibilityLabel:user1.fullName];
        [tester waitForViewWithAccessibilityLabel:[self selectionIndicatoraccessibilityLabelForUser:user1]];
        [tester tapViewWithAccessibilityLabel:user1.fullName];
        [tester waitForAbsenceOfViewWithAccessibilityLabel:[self selectionIndicatoraccessibilityLabelForUser:user1]];
    }];
}

//Test that the colors and fonts can be changed by using the UIAppearance selectors.
- (void)testToVerifyColorAndFontChangeFunctionality
{
    UIFont *testFont = [UIFont systemFontOfSize:20];
    UIColor *testColor = [UIColor redColor];
    
    LSUser *user1 = [LYRUITestUser testUserWithNumber:1];
    
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        [[LYRUIParticipantTableViewCell appearance] setTitleFont:testFont];
        [[LYRUIParticipantTableViewCell appearance] setTitleColor:testColor];
        
        LYRUIParticipantTableViewCell *cell = (LYRUIParticipantTableViewCell *)[tester waitForViewWithAccessibilityLabel:user1.fullName];
        expect(cell.titleFont).to.equal(testFont);
        expect(cell.titleColor).to.equal(testColor);
    }];
}

//Verify that the cell can be overridden and a new UI presented.
- (void)testToVerifyCustomCellClassFunctionality
{
    LSUser *user1 = [LYRUITestUser testUserWithNumber:1];
    
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    controller.cellClass = [LYRUITestParticipantCell class];
    
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        
        expect([[tester waitForViewWithAccessibilityLabel:user1.fullName] class]).to.equal([LYRUITestParticipantCell class]);
        expect([[tester waitForViewWithAccessibilityLabel:user1.fullName] class]).toNot.equal([LYRUIParticipantTableViewCell class]);
        
    }];
    //TODO - Finish This Test
}

//Verify that the row height can be configured.
- (void)testToVerifyCustomRowHeightFunctionality
{
    LSUser *user1 = [LYRUITestUser testUserWithNumber:1];
    
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    controller.rowHeight = 80;
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        
        expect([tester waitForViewWithAccessibilityLabel:user1.fullName].frame.size.height).to.equal(80);
        
    }];
}

//Verify that the sectioning can be changed by returning different values for the sectionText property (i.e. first name vs. last name).
-(void)testToVerifySectionTextPropertyFunctionality
{
    
}

//Test that attempts to change the cell class after the view is loaded results in a runtime error.
- (void)testToVerifyChangingCellClassAfterViewLoadRaiseException
{
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        [tester waitForTimeInterval:2];
        expect(^{ [modalViewController setCellClass:[UITableView class]]; }).to.raise(NSInternalInconsistencyException);
    }];
}

//Test that attempting to change the row height after the view is loaded results in a runtime error.
- (void)testToVerifyChangingRowHeightAfterViewLoadRaiseException
{
    LSUIParticipantPickerDataSource *dataSource = [LSUIParticipantPickerDataSource participantPickerDataSourceWithPersistenceManager:self.testInterface.applicationController.persistenceManager];
    LYRUIParticipantPickerController *controller = [LYRUIParticipantPickerController participantPickerWithParticipants:dataSource sortType:LYRUIParticipantPickerControllerSortTypeFirst];
    [system presentModalViewController:controller configurationBlock:^(id modalViewController) {
        [tester waitForTimeInterval:2];
        expect(^{ [modalViewController setRowHeight:80]; }).to.raise(NSInternalInconsistencyException);
    }];
}

- (NSString *)selectionIndicatoraccessibilityLabelForUser:(LSUser *)testUser
{
    return [NSString stringWithFormat:@"%@ selected", testUser.fullName];
}
@end
