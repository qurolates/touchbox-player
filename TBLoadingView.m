#import "TBLoadingView.h"
#import "TBTheme.h"

UIView *TBCreateLoadingView(NSString *message) {
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)] autorelease];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [TBTheme backgroundColor];
    UIActivityIndicatorView *indicator = [[[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    indicator.frame = CGRectMake(143, 110, 34, 34);
    indicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [indicator startAnimating];
    [view addSubview:indicator];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(20, 150, 280, 30)] autorelease];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    label.text = message;
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [TBTheme secondaryTextColor];
    label.font = [TBTheme secondaryFont];
    label.backgroundColor = [UIColor clearColor];
    [view addSubview:label];
    return view;
}
