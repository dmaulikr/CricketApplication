//
//  DatabaseController.m
//  CricketApplication
//
//  Created by Miranda Aperghis on 06/08/2012.
//  Copyright (c) 2012 JMoni. All rights reserved.
//

#import "DatabaseController.h"
#import "ThirdViewController.h"
#import "sqlite3.h"
#include "SecondViewController.h"
#include "FirstViewController.h"

@interface DatabaseController ()
@end

@implementation DatabaseController
@synthesize saveButton = _saveButton;
@synthesize tabBar;

// Creates a writable copy of the bundled default database in the application Documents directory.
- (void)createEditableCopyOfDatabaseIfNeeded {
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"cricket.db"];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success){
        return;
	}
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"cricket.db"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
	NSLog(@"\nDatabase didn't exist");
	if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}

- (void) firstTabSave {
    //Adds hometeam name to the database, if the name already exists it doesn't add it again
	[self insertStringIntoDatabase:[NSString stringWithFormat: @"INSERT INTO TEAMS (TeamName) SELECT \"%@\" WHERE NOT EXISTS (SELECT 1 FROM TEAMS WHERE TeamName = \"%@\")", homeTeam, homeTeam]];
    //Adds awayteam name to the database, if the name already exists it doesn't add it again
	[self insertStringIntoDatabase:[NSString stringWithFormat: @"INSERT INTO TEAMS (TeamName) SELECT \"%@\" WHERE NOT EXISTS (SELECT 1 FROM TEAMS WHERE TeamName = \"%@\")", awayTeam, awayTeam]];
}

- (IBAction)next:(id)sender {
	if ([self selectedIndex] == 0) {
		[[[tabBar items] objectAtIndex:1] setEnabled:YES];
		[self firstTabSave];
	} else if ([self selectedIndex] == 1) {
		[[[tabBar items] objectAtIndex:2] setEnabled:YES];
		[self firstTabSave];
		[self secondTabSave];
	} else if ([self selectedIndex] == 2) {
		//[self thirdTabSave];
        [nextButton setAction: @selector(share:)];

        nextButton.title = @"Share";
		[self firstTabSave];
		[self secondTabSave];
	}
	[self setSelectedIndex: [self selectedIndex]+1];
}
-(IBAction)share:(id) sender{
    NSLog(@"changed");
}
- (void) secondTabSave {
	//HOME TEAM
	homeTeamID = [self returnIntFromDatabase:[NSString stringWithFormat:
								 @"SELECT TeamID FROM TEAMS WHERE TeamName == '%@'", homeTeam]];
	for (int i = 0; i < [homePlayersArray count]; i++){
		[self insertStringIntoDatabase:[NSString stringWithFormat:
										@"INSERT INTO PLAYERS (TeamID, PlayerName) SELECT %d, \"%@\" WHERE NOT EXISTS (SELECT * FROM Players WHERE (PlayerName = \"%@\") AND (TeamID = %d))",
										homeTeamID, [homePlayersArray objectAtIndex:i], [homePlayersArray objectAtIndex:i], homeTeamID]];
	}
	
	//AWAY TEAM
	awayTeamID = [self returnIntFromDatabase:[NSString stringWithFormat:
											  @"SELECT TeamID FROM TEAMS WHERE TeamName == '%@'", awayTeam]];
	for (int i = 0; i < [awayPlayersArray count]; i++){
		[self insertStringIntoDatabase:[NSString stringWithFormat:
										@"INSERT INTO PLAYERS (TeamID, PlayerName) SELECT %d, \"%@\" WHERE NOT EXISTS (SELECT * FROM Players WHERE (PlayerName = \"%@\") AND (TeamID = %d))",
										awayTeamID, [awayPlayersArray objectAtIndex:i], [awayPlayersArray objectAtIndex:i], awayTeamID]];
	}
}

- (void) thirdTabSave {
	[self insertStringIntoDatabase:[NSString stringWithFormat:
									@"INSERT INTO GAMES (HomeID, AwayID, GameDate, TossResult, Decision, MatchType, OversOrDays, UmpireOne, UmpireTwo) VALUES (%d, %d, '%@', \"%@\", \"%@\", \"%@\", %d, \"%@\", \"%@\")",
									homeTeamID, awayTeamID, strDate, tossWonBy, decision, matchType, numberOversOrDays, umpireOne, umpireTwo]];
	disableElements = YES;
}

- (int)returnIntFromDatabase:(NSString *)string {
	int returnThis = -1;
	const char *dbpath = [writableDBPath UTF8String];
	sqlite3_stmt *statement;
    if (sqlite3_open(dbpath, &cricketDB) == SQLITE_OK)
    {
		const char *stmt = [string UTF8String];
		sqlite3_prepare_v2(cricketDB, stmt, -1, &statement, NULL);
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSLog(@"\nAccess worked");
			returnThis = sqlite3_column_int(statement, 0);
		}
		sqlite3_finalize(statement);
		sqlite3_close(cricketDB);
	} else {
		NSLog(@"\nCould not access DB");
	}
	return returnThis;
}

- (void)insertStringIntoDatabase:(NSString *)string {
	const char *dbpath = [writableDBPath UTF8String];
	sqlite3_stmt *statement;
    if (sqlite3_open(dbpath, &cricketDB) == SQLITE_OK)
    {
		const char *stmt = [string UTF8String];
		sqlite3_prepare_v2(cricketDB, stmt, -1, &statement, NULL);
		if (sqlite3_step(statement) == SQLITE_DONE) {
			NSLog(@"\nAccess worked");
		} else {
			NSLog(@"\nAccess failed");
		}
		sqlite3_finalize(statement);
		sqlite3_close(cricketDB);
	} else {
		NSLog(@"\nCould not access DB");
	}
}

/*- (BOOL)tabBarController:(UITabBarController *)aTabBarController shouldSelectViewController:(UIViewController *)viewController
{
	NSLog(@"HELLO");
	if (
		([aTabBarController.viewControllers objectAtIndex:1] == viewController) ||
		([aTabBarController.viewControllers objectAtIndex:2] == viewController)
		)
	{
		// Disable switch to tab 1 and 2
		// Check: otherViewController to enable
		// Check: SomeViewObject to disable
		return NO;
	}
	else
	{
		// Tab ok at index 0
		return YES;
	}
}*/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self createEditableCopyOfDatabaseIfNeeded];
	for (int i = 1; i < 3; i++){
		[[[tabBar items] objectAtIndex:i] setEnabled:FALSE];
	}
}

- (void)viewDidUnload
{
    [self setSaveButton:nil];
	[self setTabBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
