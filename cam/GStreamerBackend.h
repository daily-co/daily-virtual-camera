#import <Foundation/Foundation.h>

#include <gst/gst.h>
#include <gst/app/app.h>

@interface GStreamerBackend : NSObject

@property int width;
@property int height;
@property int frameRate;

@property GstElement *pipeline;
@property GstAppSink *appsink;

- (instancetype)initWithPipeline:(NSString *)pipeline
                           width:(int)width
                          height:(int)height
                       frameRate:(int)frameRate;

- (void)linkPipeline:(GstPad*)new_pad;

- (NSData *)nextFrameBuffer;

@end
