//
//  GStreamerBackend.m
//  cam
//
//  Created by Aleix Conchillo Flaque on 9/14/22.
//

#import "GStreamerBackend.h"

@implementation GStreamerBackend

static void
decodebin_pad_added_cb(GstElement* decodebin, GstPad* new_pad, gpointer user_data)
{
	GStreamerBackend* backend = (__bridge GStreamerBackend*)user_data;

	GstCaps* caps = gst_pad_get_current_caps(new_pad);
	gchar* caps_str = gst_caps_to_string(caps);
	gst_caps_unref(caps);

	// Only process video streams.
	if (g_strrstr(caps_str, "video/x-raw") != NULL) {
		[backend linkPipeline:new_pad];
	}
	g_free(caps_str);
}


-(instancetype) initWithPipeline:(NSString *)pipeline
						   width:(int)width
						  height:(int)height
					   frameRate:(int)frameRate {
    gst_init(NULL, NULL);

    self = [super init];
    if (self) {
		_width = width;
		_height = height;
		_frameRate = frameRate;
		
		_pipeline = gst_pipeline_new(NULL);
		
        GError *error = NULL;
        GstElement *src = gst_parse_bin_from_description([pipeline cString], true, &error);
		
		GstElement* decodebin = gst_element_factory_make("decodebin", NULL);
		g_signal_connect(
			 G_OBJECT(decodebin),
			 "pad-added",
			 (GCallback)decodebin_pad_added_cb,
			 (__bridge void*) self);

        _appsink = (GstAppSink*)gst_element_factory_make("appsink", NULL);

		// appsink caps
		GstCaps* caps = gst_caps_new_simple(
			"video/x-raw",
			"format",
			G_TYPE_STRING,
			"BGRA",
			"framerate",
			GST_TYPE_FRACTION,
			frameRate,
			1,
			"width",
			G_TYPE_INT,
			width,
			"height",
			G_TYPE_INT,
			height,
			NULL);
		gst_app_sink_set_caps(_appsink, caps);
		gst_caps_unref(caps);

		gst_bin_add_many(GST_BIN(_pipeline), src, decodebin, GST_ELEMENT(_appsink), NULL);

		gst_element_link(src, decodebin);
        gst_element_sync_state_with_parent(src);
		gst_element_sync_state_with_parent(decodebin);

        gst_element_set_state(_pipeline, GST_STATE_PLAYING);
    }
    return self;
}

-(void) linkPipeline:(GstPad*)new_pad
{
	GstElement* queue = gst_element_factory_make("queue", NULL);
	GstElement* videorate = gst_element_factory_make("videorate", NULL);
	GstElement* ratefilter = gst_element_factory_make("capsfilter", NULL);
	GstElement* videoscale = gst_element_factory_make("videoscale", NULL);
	GstElement* scalefilter = gst_element_factory_make("capsfilter", NULL);
	GstElement* videoconvert = gst_element_factory_make("videoconvert", NULL);
	GstElement* convertfilter = gst_element_factory_make("capsfilter", NULL);
	
	gst_bin_add_many(GST_BIN(_pipeline), queue, videorate, ratefilter, videoscale, scalefilter, videoconvert, convertfilter, NULL);

	// videorate caps
	GstCaps* caps = gst_caps_new_simple(
		"video/x-raw",
		"framerate",
		GST_TYPE_FRACTION,
		_frameRate,
		1,
		NULL);
	g_object_set(G_OBJECT(ratefilter), "caps", caps, NULL);
	gst_caps_unref(caps);

	// videoscale caps
	caps = gst_caps_new_simple(
		"video/x-raw",
		"width",
		G_TYPE_INT,
		_width,
		"height",
		G_TYPE_INT,
		_height,
		NULL);
	g_object_set(G_OBJECT(scalefilter), "caps", caps, NULL);
	gst_caps_unref(caps);

	// videoconvert caps
	caps = gst_caps_new_simple(
		"video/x-raw",
		"format",
		G_TYPE_STRING,
		"BGRA",
		NULL);
	g_object_set(G_OBJECT(convertfilter), "caps", caps, NULL);
	gst_caps_unref(caps);

	GstPad* sinkpad = gst_element_get_static_pad(queue, "sink");
	gst_pad_link(new_pad, sinkpad);
	gst_object_unref(sinkpad);

	gst_element_link_many(queue, videorate, ratefilter, videoscale, scalefilter, videoconvert, convertfilter, GST_ELEMENT(_appsink), NULL);
	gst_element_sync_state_with_parent(queue);
	gst_element_sync_state_with_parent(videorate);
	gst_element_sync_state_with_parent(ratefilter);
	gst_element_sync_state_with_parent(videoscale);
	gst_element_sync_state_with_parent(scalefilter);
	gst_element_sync_state_with_parent(videoconvert);
	gst_element_sync_state_with_parent(convertfilter);
	gst_element_sync_state_with_parent(GST_ELEMENT(_appsink));
}

-(NSData*) nextFrameBuffer
{
	if (_appsink) {
		GstSample *sample = gst_app_sink_pull_sample(_appsink);
		GstBuffer *buffer = gst_sample_get_buffer(sample);

		GstMapInfo bufmap;
		gst_buffer_map(buffer, &bufmap, GST_MAP_READ);

		NSData *data = [NSData dataWithBytes:bufmap.data length:bufmap.size];

		gst_buffer_unmap(buffer, &bufmap);

		gst_sample_unref(sample);

		return data;
	}
	return nil;
}

@end
