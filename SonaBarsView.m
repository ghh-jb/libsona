#import "public/SonaBarsView.h"

#define MIN_HZ 20
#define MAX_HZ 20000

@interface SonaBarsView ()
@end

@implementation SonaBarsView
// we need a different setter method, because we also need to create layers
-(void) renderBars {
	// Calculate offset to center bars
	float leftOffset = (self.frame.size.width - (self.pointSpacing + self.pointWidth) * self.pointNumber - self.pointSpacing) / 2;

	for(int i = 0; i < self.pointNumber; i++) {
		CALayer *bar = [CALayer layer];

		bar.frame = CGRectMake(leftOffset + i * (self.pointWidth + self.pointSpacing), self.frame.size.height, self.pointWidth, 0);
		bar.backgroundColor = self.pointColor.CGColor;
		bar.cornerRadius = self.pointRadius;
		[self.layer addSublayer:bar];
	}
}

-(void) start {
	// TODO: Find a way to re render layers every time 

	// We only want to create bars just ONE TIME
	if(self.layer.sublayers.count == 0) [self renderBars];

	// Start audio connection
	self.isMusicPlaying = YES;
	[self.audioSource startConnection];
}

-(void) stop {
	self.isMusicPlaying = NO;
	[self.audioSource stopConnection];
}


-(void) resume {
	if (!self.isMusicPlaying) return;

	[self.audioSource startConnection];
}

-(void) pause {
	if (!self.isMusicPlaying) return;

	[self.audioSource stopConnection];
}

-(void) newAudioDataWasReceived:(float *)buffer withLength:(int)length {
	
	// We want fft
	if(length == 480) {
		[self.audioProcessor fromRawToFFTAirpods:buffer withLength:length];

	} else {
		[self.audioProcessor fromRawToFFT:buffer withLength:length];
	}
}

- (void) newAudioDataWasProcessed:(float *)frames withLength:(int)length {

	// We want bar frequency visualizer

	// I don't know too much about audio visualization, but I will use a kind of octave bands.
	// with max capacity 10.
	float octaves[10] = {0};
	float offset = 10 / self.pointNumber;
	float freq = 0;
	float binWidth = MAX_HZ / length;

	int band = 0;
	float bandEnd = MIN_HZ * pow(2, 1);

	for(int i = 0; i < length; i++) {
		freq = i > 0 ? i * binWidth : MIN_HZ;

		octaves[band] += frames[i];

		if(freq > offset * bandEnd) {
			band += 1;
			bandEnd = MIN_HZ * pow(2, band + 1);
		}
	}


	// Render new bars
	for(int i = 0; i < self.pointNumber; i++) {
		CALayer *bar = self.layer.sublayers[i];
		float heightMultiplier = octaves[i] * self.pointSensitivity > 0.95 ? 0.95 : octaves[i] * self.pointSensitivity;

		dispatch_async(dispatch_get_main_queue(), ^{
			bar.backgroundColor = self.pointColor.CGColor;
			bar.frame = CGRectMake(bar.frame.origin.x, self.frame.size.height, bar.frame.size.width, -fabs(heightMultiplier * self.frame.size.height));
		});
	}	
}

@end