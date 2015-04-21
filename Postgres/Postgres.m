//
//  Postgres.m
//  Postgres
//
//  Created by John Wang on 3/25/11.
//  Copyright 2011 Fresh Blocks LLC. All rights reserved.
//

#import "Postgres.h"

#define LAUNCHCTL @"/bin/launchctl"
#define WHICH @"/usr/bin/which"
#define ECHO @"/bin/echo"
#define FIND @"/usr/bin/find"
#define PG_CTL @"pg_ctl"
#define USR_LOCAL @"/usr/local"
#define COPY @"/bin/cp"
#define MKDIR @"/bin/mkdir"
#define HOMEBREW_PATH @"/usr/local/bin/pg_ctl"

@implementation Postgres
@synthesize path = _path;
@synthesize startButton = _startButton;
@synthesize statusLabel = _statusLabel;
@synthesize autoStartCheckBox = _autoStartCheckBox;
@synthesize detailInformationText = _detailInformationText;
@synthesize progressIndicator = _progressIndicator;
@synthesize postgres = _postgres;
@synthesize serverLog = _serverLog;
@synthesize pgctl = _pgctl;
@synthesize startedSubtext = _startedSubtext;
@synthesize statusImage = _statusImage;

- (void)updateChrome {
    NSString *startedPath = [[self bundle] pathForResource:@"started" ofType:@"png"];
    NSImage *started = [[NSImage alloc] initWithContentsOfFile:startedPath];
    
    NSString *stoppedPath = [[self bundle] pathForResource:@"stopped" ofType:@"png"];
    NSImage *stopped = [[NSImage alloc] initWithContentsOfFile:stoppedPath];
    
    if (_isRunning) {
        [self.startButton setTitle:@"Stop Postgresql Server"];
        [self.detailInformationText setTitleWithMnemonic:@"The Postgresql Database Server is started and ready for client connections. To shut the Server down, use the \"Stop Postgresql Server\" button."];
        [self.statusLabel setTextColor:[NSColor greenColor]];
        [self.statusLabel setTitleWithMnemonic:@"Running"];
        [self.startedSubtext setHidden:NO];
        [self.statusImage setImage:started]; 
        
    }
    else {
        [self.startButton setTitle:@"Start Postgresql Server"];
        [self.detailInformationText setTitleWithMnemonic:@"The Postgresql Database Server is currently stopped. To start it, use the \"Start PostgreSQL Server\" button."];
        [self.statusLabel setTitleWithMnemonic:@"Stopped"];
        [self.statusLabel setTextColor:[NSColor redColor]];
        [self.startedSubtext setHidden:YES];
        [self.statusImage setImage:stopped];
    }
    [self.progressIndicator stopAnimation:self];
}

- (NSString *)runCLICommand:(NSString *)command arguments:(NSArray *)args waitUntilExit:(BOOL)wait {
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:command];
    [task setArguments: args];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    //The magic line that keeps your log where it belongs
    [task setStandardInput:[NSPipe pipe]];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    if (wait) {
        [task waitUntilExit];
    }
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data
                                   encoding: NSUTF8StringEncoding];
    return string;    
}

- (NSString *)runCLICommand:(NSString *)command arguments:(NSArray *)args {
    return [self runCLICommand:command arguments:args waitUntilExit:NO];
}

- (void)checkServerStatus {
    // Find out if Postgres server is running
    NSArray *args = [NSArray arrayWithObjects: @"-D", self.postgres, @"status", nil];
    
    // clean the pg_ctl from whitespaces
    self.pgctl = [self.pgctl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *result = [self runCLICommand:self.pgctl arguments:args];
    //pg_ctl: server is running
    if ([result rangeOfString:@"pg_ctl: server is running"].location != NSNotFound) {
        _isRunning = YES;        
    }
    else {
        _isRunning = NO;
    }
    
    // Set the running/stopped label and set the button text to correct
    // Check if Auto-start is enabled and set checkbox accordingly
    args = [NSArray arrayWithObjects:@"list",@"homebrew.mxcl.postgresql", nil];
    NSString *autoS = [self runCLICommand:LAUNCHCTL arguments:args waitUntilExit:NO];
    
    if ([autoS length] == 0 || [autoS isEqualToString:@"launchctl list returned unknown response"]) {
        [self.autoStartCheckBox setState:0];
    }
    else {
        [self.autoStartCheckBox setState:1];
    }
    
    [self performSelectorOnMainThread:@selector(updateChrome) withObject:nil waitUntilDone:NO];
    
}

- (void)startup {
    NSArray *args = nil;
    
    // Find the Postgres Database
    // first cheat and look for PGDATA
    args = [NSArray arrayWithObjects:@"$PGDATA", nil];
    NSString *PGDATA = [self runCLICommand:ECHO arguments:args];
    // if that's not found, look for postgresql.conf in /usr/local
    if ([PGDATA rangeOfString:@"PGDATA"].location != NSNotFound) {        
        args = [NSArray arrayWithObjects:USR_LOCAL,@"-type", @"f", @"-name", @"postgresql.conf", nil];
        PGDATA = [self runCLICommand:FIND arguments:args];
    }
    
    // remove the /postgresql.conf from the path along with whitespaces and newline characters
    self.postgres = [PGDATA stringByDeletingLastPathComponent];
    self.postgres = [self.postgres stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Find the pg_ctl
    args = [NSArray arrayWithObjects: PG_CTL, nil];
    self.pgctl = [self runCLICommand:WHICH arguments:args];    

    // Don't proceed. Disable everything.
    if ([self.pgctl length] == 0) {
        self.pgctl = HOMEBREW_PATH;
        //[self.startButton setEnabled:NO];
        //[self.autoStartCheckBox setEnabled:NO];
        [self checkServerStatus];
    }
    else {
        [self checkServerStatus];        
    }
}

// For checking after user closes or choses Show All option.
- (void)didSelect {
    [self startup];
}

- (void)mainViewDidLoad
{
    _isRunning = NO;
    [self startup];

}

- (IBAction)startStopServer:(id)sender {
    
    [self.progressIndicator startAnimation:self];

    // pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start
    // pg_ctl -D /usr/local/var/postgres stop -s -m fast
    self.serverLog = @"/usr/local/var/postgres/server.log";

    NSArray *args = nil;
    if(_isRunning) {
        [self.startButton setTitle:@"Stop Postgresql Server"];
        args = [NSArray arrayWithObjects: @"-D", self.postgres, @"stop", @"-s", @"-m", @"fast", nil];
    }
    else {
        [self.startButton setTitle:@"Start Postgresql Server"];
        args = [NSArray arrayWithObjects: @"-D", self.postgres, @"-l", self.serverLog, @"start", nil];        
    }
    [self runCLICommand:self.pgctl arguments:args waitUntilExit:YES];
    
    // update the chrome after done
    [self performSelector:@selector(checkServerStatus) withObject:nil afterDelay:3.0];
}

- (IBAction)autoStartChanged:(id)sender {
    NSString *result = nil;
    NSArray *args = nil;
    
    [self.progressIndicator startAnimation:self];
    
    NSString *launch_agents = [@"~/Library/LaunchAgents/" stringByExpandingTildeInPath];
    NSString *plist = [@"~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist" stringByExpandingTildeInPath];
    
    if ([self.autoStartCheckBox state] == 0) {        
        // launchctl unload -w ~/Library/LaunchAgents/org.postgresql.postgres.plist
        args = [NSArray arrayWithObjects:@"unload", @"-w", plist, nil];
        result = [self runCLICommand:LAUNCHCTL arguments:args];
        
    } else {        
        // mkdir -p ~/Library/LaunchAgents
        args = [NSArray arrayWithObjects:@"-p", launch_agents, nil];
        result = [self runCLICommand:MKDIR arguments:args waitUntilExit:YES];
        
        // find the postgres.plist in the /usr/local
        args = [NSArray arrayWithObjects:USR_LOCAL,@"-type", @"f", @"-name", @"homebrew.mxcl.postgresql.plist", nil];
        result = [self runCLICommand:FIND arguments:args waitUntilExit:YES];
        NSArray *lines = [result componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        if ([lines count] > 0) {
            result = [lines objectAtIndex:0];

            // cp /usr/local/Cellar/postgresql/9.0.3/org.postgresql.postgres.plist ~/Library/LaunchAgents/
            args = [NSArray arrayWithObjects:result, launch_agents, nil];
            result = [self runCLICommand:COPY arguments:args waitUntilExit:YES];
        }
        
        // launchctl load -w ~/Library/LaunchAgents/org.postgresql.postgres.plist
        args = [NSArray arrayWithObjects:@"load", @"-w", plist, nil];
        result = [self runCLICommand:LAUNCHCTL arguments:args];
    }
    // update the chrome after done
    [self performSelector:@selector(checkServerStatus) withObject:nil afterDelay:3.0];
}


@end
