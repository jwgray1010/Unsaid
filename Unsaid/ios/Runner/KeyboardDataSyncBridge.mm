#import <Flutter/Flutter.h>

@interface KeyboardDataSyncBridge : NSObject<FlutterPlugin>
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
@end

@implementation KeyboardDataSyncBridge

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"com.unsaid/keyboard_data_sync"
            binaryMessenger:[registrar messenger]];
  KeyboardDataSyncBridge* instance = [[KeyboardDataSyncBridge alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* appGroupId = @"group.com.example.unsaid";
  NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
  
  if ([@"getAllPendingKeyboardData" isEqualToString:call.method]) {
    NSArray* pendingData = [sharedDefaults arrayForKey:@"pendingKeyboardData"];
    if (pendingData == nil) {
      pendingData = @[];
    }
    result(pendingData);
  } else if ([@"getKeyboardStorageMetadata" isEqualToString:call.method]) {
    NSDictionary* metadata = [sharedDefaults dictionaryForKey:@"keyboardStorageMetadata"];
    if (metadata == nil) {
      metadata = @{};
    }
    result(metadata);
  } else if ([@"clearAllPendingKeyboardData" isEqualToString:call.method]) {
    [sharedDefaults removeObjectForKey:@"pendingKeyboardData"];
    [sharedDefaults removeObjectForKey:@"keyboardStorageMetadata"];
    [sharedDefaults synchronize];
    result(@(YES));
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
