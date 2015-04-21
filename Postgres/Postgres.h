//
//  Postgres.h
//  Postgres
//
//  Created by John Wang on 3/25/11.
//  Copyright 2011 Fresh Blocks LLC. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <AppKit/AppKit.h>

@interface Postgres : NSPreferencePane {
@private
    NSString *_path;
    NSButton *__strong _startButton;
    NSTextField *__strong _statusLabel;
    NSButton *__strong _autoStartCheckBox;
    NSTextField *__strong _detailInformationText;
    NSProgressIndicator *__strong _progressIndicator;
    
    NSString *_serverLog;
    NSString *_postgres;
    NSString *_pgctl;
    NSTextField *__strong _startedSubtext;
    NSImageView *__strong _statusImage;
    
    BOOL _isRunning;
    
}
@property(nonatomic, strong) NSString *path;
@property (strong) IBOutlet NSButton *startButton;
@property (strong) IBOutlet NSTextField *statusLabel;
@property (strong) IBOutlet NSButton *autoStartCheckBox;
@property (strong) IBOutlet NSTextField *detailInformationText;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, strong) NSString *serverLog;
@property (nonatomic, strong) NSString *postgres;
@property (nonatomic, strong) NSString *pgctl;
@property (strong) IBOutlet NSTextField *startedSubtext;
@property (strong) IBOutlet NSImageView *statusImage;

- (void)mainViewDidLoad;
- (IBAction)startStopServer:(id)sender;
- (IBAction)autoStartChanged:(id)sender;

@end
