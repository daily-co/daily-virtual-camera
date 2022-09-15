//
//  GStreamerBackend.m
//  cam
//
//  Created by Aleix Conchillo Flaque on 9/14/22.
//

#import "GStreamerBackend.h"

@implementation GStreamerBackend

-(instancetype) initWithPipeline:(NSString *)pipeline {
    gst_init(NULL, NULL);

    self = [super init];
    if (self) {
        _pipelineStr = pipeline;

        GError *error = NULL;
        _pipeline = gst_parse_launch([_pipelineStr cString], &error);

        GstElement* src = gst_bin_get_by_name(GST_BIN(_pipeline), "src");

        _appsink = (GstAppSink*)gst_element_factory_make("appsink", NULL);
        gst_element_link(src, GST_ELEMENT(_appsink));

        gst_bin_add(GST_BIN(_pipeline), GST_ELEMENT(_appsink));
        gst_element_sync_state_with_parent(GST_ELEMENT(_appsink));

        gst_element_set_state(_pipeline, GST_STATE_PLAYING);
    }
    return self;
}

-(NSData*) nextFrameBuffer
{
    GstSample *sample = gst_app_sink_pull_sample(_appsink);
    GstBuffer *buffer = gst_sample_get_buffer(sample);

    GstMapInfo bufmap;
    gst_buffer_map(buffer, &bufmap, GST_MAP_READ);

    NSData *data = [NSData dataWithBytes:bufmap.data length:bufmap.size];

    gst_buffer_unmap(buffer, &bufmap);

    gst_sample_unref(sample);

    return data;
}

@end
