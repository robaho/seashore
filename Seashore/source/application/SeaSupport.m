#import <StoreKit/StoreKit.h>
#import "SeaSupport.h"
#import "SeaDocument.h"
#import "SeaWindowContent.h"

#define kSupportSeashore @"seashore_support"

@implementation SeaSupport

- (SeaSupport*)init
{
    NSDictionary *dict = @{(id)kSecClass: (id)kSecClassGenericPassword,
                           (id)kSecAttrService: @"purchases",
                           (id)kSecAttrAccount: @"seashore.app",
                           (id)kSecAttrAccessGroup: @"seashore.app"};

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dict, NULL);
    if(status==errSecSuccess) {
        isSupported=TRUE;
    }

    return self;
//    NSData *dataReceipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
//    if(dataReceipt) {
//        NSString *receipt = [dataReceipt base64EncodedStringWithOptions:0];
//        [self verifyReceipt:receipt];
//    }
}

- (void)awakeFromNib
{
    NSBundle *myBundle = [NSBundle mainBundle];
    NSString *sFile= [myBundle pathForResource:@"Support Seashore" ofType:@"rtf"];
    [self->textView readRTFDFromFile:sFile];
    [self->textView setTextColor:[NSColor textColor]];

    [self->window setDelegate:self];
}

- (void)windowDidBecomeMain:(id)window
{
    if(!isSupported){
        __block int count=10;
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            count--;
            if(count>0) {
                NSString *title = [NSString stringWithFormat:@"Nah, Maybe Later (%d)",count];
                [self->maybeLater setTitle:title];
            } else {
                [self->maybeLater setTitle:@"Nah, Maybe Later"];
                [self->maybeLater setEnabled:TRUE];
                [timer invalidate];
            }
        }];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

- (IBAction)showSupportSeashore:(id)sender {
    if(timer)
        [timer invalidate];
    [maybeLater setEnabled:FALSE];
    [supportSeashore setTitle:@"Support Seashore $5.99 USD"];
    [supportSeashore setEnabled:TRUE];
    [window setLevel:NSModalPanelWindowLevel];
    [window makeKeyAndOrderFront:self];
}

- (void)doSeashoreSupported
{
    NSDictionary *dict = @{(id)kSecClass: (id)kSecClassGenericPassword,
                (id)kSecAttrService: @"purchases",
                (id)kSecAttrAccount: @"seashore.app",
                (id)kSecAttrAccessGroup: @"seashore.app",
                (id)kSecValueData: @"I support Seashore"};

    SecItemAdd((__bridge CFDictionaryRef)dict,NULL);

    isSupported = TRUE;

    [self hideBanner:self];
}

- (void)doSeashoreError:(NSString*)error
{
    [supportSeashore setTitle:error];
    [supportSeashore setEnabled:FALSE];
    [supportSeashore setToolTip:error];
}

- (IBAction)hideBanner:(id)sender {
    [window close];

    NSArray *documents = [[NSDocumentController sharedDocumentController] documents];

    for (SeaDocument *doc in documents) {
        [[[doc window] contentView] hideBanner];
    }
}

- (BOOL)isSupportPurchased
{
    return isSupported;
}

- (void)supportSeashore:(id)sender
{
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments");

        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kSupportSeashore]];
        productsRequest.delegate = self;
        [productsRequest start];
    }
    else{
        [supportSeashore setTitle:@"Purchases Not Supported"];
        [supportSeashore setEnabled:FALSE];

        NSLog(@"User cannot make payments due to parental controls");
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    SKProduct *validProduct = nil;
    int count = [response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        [self purchase:validProduct];
    }
    else if(!validProduct){
        [self performSelectorOnMainThread:@selector(doSeashoreError:) withObject:@"Products Not Available" waitUntilDone:FALSE];
        NSLog(@"no valid products.");
    }
}

- (void)purchase:(SKProduct *)product
{
    SKPayment *payment = [SKPayment paymentWithProduct:product];

    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (IBAction)restore:(id)sender
{
    NSLog(@"restoring purchases");
    //this is called when the user restores purchases, you should hook this up to a button
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"purchasing...");
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"purchased.");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self performSelectorOnMainThread:@selector(doSeashoreSupported) withObject:NULL waitUntilDone:FALSE];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"restored.");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self performSelectorOnMainThread:@selector(doSeashoreSupported) withObject:NULL waitUntilDone:FALSE];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"transaction failed");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self performSelectorOnMainThread:@selector(doSeashoreError:) withObject:[transaction.error localizedDescription] waitUntilDone:FALSE];
                break;
            case SKPaymentTransactionStateDeferred:
                [self performSelectorOnMainThread:@selector(doSeashoreError:) withObject:@"Payment Deferred" waitUntilDone:FALSE];
                NSLog(@"transaction deferred...");
                break;
        }
    }
}

- (void) verifyReceipt:(NSString*)receiptBase64
{
    NSString *url = @"https://buy.itunes.apple.com/verifyReceipt";
    NSString *sandbox_url = @"https://sandbox.itunes.apple.com/verifyReceipt";
    NSDictionary *jsonBodyDict = @{@"receipt-data":receiptBase64};
    NSData *jsonBodyData = [NSJSONSerialization dataWithJSONObject:jsonBodyDict options:kNilOptions error:nil];

    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.HTTPMethod = @"POST";

    [request setURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:jsonBodyData];

    NSURLResponse *response = [[NSURLResponse alloc] init];
    NSError *error = [NSError alloc];

    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSDictionary *receipt = [NSJSONSerialization JSONObjectWithData:result options:0 error:NULL];
    NSNumber *status = receipt[@"status"];
    if([status intValue]==21002){
        [request setURL:[NSURL URLWithString:sandbox_url]];
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        receipt = [NSJSONSerialization JSONObjectWithData:result options:0 error:NULL];
    }

    NSLog(@"receipt %@",receipt);
}
@end
