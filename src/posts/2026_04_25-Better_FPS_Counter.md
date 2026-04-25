[Home](../index.md)

# Better FPS Counter

I recently read [an article](https://vplesko.com/posts/how_to_implement_an_fps_counter.html) about implementing FPS counters which covers a number of different methods, the benefits and drawbacks; though, it focuses exlusively on simple moving averages (SMA). I'm not much of a game developer, but I've done enough graphics programming that I've encountered this a number of times and instead gravitate toward using [exponential moving average (EMA)](https://en.wikipedia.org/wiki/Exponential_smoothing), which I haven't seen discussed much online.

I'm not going to attempt to explain EMA or SMA or the tradeoffs from a mathematical/signal processing perspective. I don't have much experience in that field, and I'm more interested in it's computer science application. The plain and simple reason for preferring EMA is that it's calculation has constant time and space complexity regardless of window size, while also being easier to implement, in my opinion. The standard formula for EMA is:

$$s_i = \alpha x_i + (1-\alpha)s_{i-1}$$

For our application, we will be keeping track of the moving average of frame duration which we will denote $\bar{d}_i$. Our smoothed frames per second that we display to the screen as a counter is trivially calculated as $1/\bar{d}_i$. We let $d_i$ be the duration of the current frame and $\bar{d}_{i-1}$ be the moving average after the previous frame. So the formula is:

$$\bar{d_i} = \alpha d_i + (1-\alpha)\bar{d}_{i-1}$$


## Simple Smoothing Factor

The most important thing we need to figure out is what value do we use for $\alpha$. When using EMA on stocks it is common to see visualizations of n-day EMA. The way they figure $\alpha$ for this caluclation is using the concept of average age of datapoints. For an SMA with fixed sample window, the average age of datapoints is simply $n/2$. For an EMA, the average age is $\frac{1-\alpha}{\alpha}$. By setting these two equal, we derive a forumla for $\alpha$, whereby the EMA smoothing approximates the smoothing of an n-sample SMA:

$$
\alpha=\frac{2}{n+1}
$$

This can already be used as is for a dirty and simple FPS counter where your goal is to sample the average over last n frames. As discussed in the original post, the problems with using fixed sample averages is that it dosen't properly depend on time. Espesially when graphing FPS, a slower framerate will look quite smooth, while a high framerate will be jittery.

## Time-based Smoothing Factor

What we actually want is the average framerate over the last $T$ duration in some time unit. To do this we will consider that we want our EMA to maintain a constant average age of datapoints $T$, therefore:

$$T = \alpha (0) + (1-\alpha)(T + d_i)$$
$$\alpha = \frac{d_i}{T + d_i}$$

Substituting this into our original forumla we get:

$$\bar{d_i} = \frac{d_i}{T + d_i} d_i + (1-\frac{d_i}{T + d_i})\bar{d}_{i-1}$$

And after some simplification:

$$\bar{d}_i = \frac{d_i^2 + \bar{d}_{i-1}T}{T+d_i}$$

So if we want to approximate the smoothing of a duration based SMA like the method arrived at in the original blog, we set $T$ to the SMA window duration divided by two because the average age of time windowed SMA data is simply half the window duration.

## FPS Calculation Routine Using SDL

```C
static Uint64 prev_frame_start;

float moving_average_of_frame_duration_sec(
    float prev_avg_dur,
    float sample_dur_sec
) {
    Uint64 cur_frame_start = SDL_GetPerformanceCounter();
    float frame_dur_unitless = (float)(cur_frame_start-prev_frame_start);
    prev_frame_start = cur_frame_start;
    float frame_dur = frame_dur_unitless/(float)SDL_GetPerformanceFrequence();
    float t = sample_dur/2.0f;
    return (frame_dur*frame_dur + prev_avg_dur*t)/(t+frame_dur);
}
```