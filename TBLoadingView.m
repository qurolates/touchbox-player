#import "TBLoadingView.h"

UIView *TBCreateLoadingView(NSString *message) {
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)] autorelease];
    UIActivityIndicatorView *indicator = [[[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    indicator.frame = CGRectMake(143, 110, 34, 34);
    [indicator startAnimating];
    [view addSubview:indicator];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(20, 150, 280, 30)] autorelease];
    label.text = message;
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor grayColor];
    label.backgroundColor = [UIColor clearColor];
    [view addSubview:label];
    return view;
}
