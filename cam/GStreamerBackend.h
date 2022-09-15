#import <Foundation/Foundation.h>

#include <gst/gst.h>
#include <gst/app/app.h>

@interface GStreamerBackend : NSObject

@property NSString *pipelineStr;

@property GstElement *pipeline;

@property GstAppSink *appsink;

-(instancetype) initWithPipeline:(NSString *)pipeline;

-(NSData*) nextFrameBuffer;

@end
