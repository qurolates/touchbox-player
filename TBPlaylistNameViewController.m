#import "TBPlaylistNameViewController.h"
#import "TBTheme.h"

@implementation TBPlaylistNameViewController
- (id)initWithTarget:(id)target action:(SEL)action {
    self = [super init];
    if (self) { _target = target; _action = action; self.title = @"New Playlist"; }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [TBTheme backgroundColor];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
        action:@selector(cancel:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self
        action:@selector(save:)] autorelease];
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(15, 30, MAX(0.0f, self.view.bounds.size.width - 30), 36)];
    _textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    _textField.placeholder = @"Playlist Name";
    _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _textField.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:_textField];
    [_textField becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:) name:TBThemeDidChangeNotification object:nil];
    [self themeChanged:nil];
}
- (void)themeChanged:(NSNotification *)notification { self.view.backgroundColor = [TBTheme backgroundColor]; _textField.backgroundColor = [TBTheme elevatedBackgroundColor]; _textField.textColor = [TBTheme primaryTextColor]; }
- (void)cancel:(id)sender { [self dismissModalViewControllerAnimated:YES]; }
- (void)save:(id)sender {
    NSString *name = [[_textField.text copy] autorelease];
    if (![name length]) return;
    [self dismissModalViewControllerAnimated:NO];
    if ([_target respondsToSelector:_action]) [_target performSelector:_action withObject:name];
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [_textField release]; [super dealloc]; }
@end
