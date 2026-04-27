---
title: "Exponentially Smoothed FPS Counters"
description: "Exploring how to apply an interesting numerical technique with constant time and space complexity to FPS counters."
---

I recently read [this article](https://vplesko.com/posts/how_to_implement_an_fps_counter.html) about implementing FPS counters which looks at a few different methods, covering the benefits and drawbacks; while interesting, it focuses exclusively on the use of simple moving averages (SMA). I'm not a game developer, but I've done enough graphical programming that I've encountered this problem a number of times and instead tend to opt for [exponential moving average (EMA)](https://en.wikipedia.org/wiki/Exponential_smoothing), which I haven't seen discussed much online for this use case.

I'm not going to explain EMA (because I'd just be rephrasing the first paragraph of Wikipedia) or analyze the tradeoffs from a signal processing perspective. I don't have much experience in that field, and I'm more interested in its applications to software engineering. The plain and simple reason for preferring EMA is that it has constant time and space complexity regardless of window size, while also being easier to implement, in my opinion. These properties make it an interesting technique for low-overhead moving average calculations on just about any real-time metric.

For our application, we will be keeping track of the moving average of frame duration which we denote $\bar{d}_i$. Our smoothed frames per second that we display to the screen as a counter is trivially calculated as $1/\bar{d}_i$. We let $d_i$ be the duration of the current frame and $\bar{d}_{i-1}$ be the moving average after the previous frame. So the formula is:

$$\bar{d_i} = \alpha d_i + (1-\alpha)\bar{d}_{i-1}$$


## Fixed Smoothing Factor

The most important thing to figure out is what value we use for $\alpha$, which can be thought of as the smoothing or forgetting factor. When using EMA on stocks it is common to see visualizations of n-day EMA. The way they figure out $\alpha$ for this financial calculation relies on the concept of the average age of datapoints. For an SMA with a fixed sample window, the average age of datapoints is simply $n/2$. For fixed frequency EMA, the average age of its datapoints is $(1-\alpha)/\alpha$. By setting these two as equal, we derive a formula for $\alpha$, whereby the EMA smoothing approximates the smoothing of an n-sample SMA:

$$
\alpha=\frac{2}{n+1}
$$

This can be used as is for a quick and dirty FPS counter if you just want the average over last n frames. However, as discussed in the original post, the problem with using fixed sample averages for FPS is that it doesn't properly depend on time. This means that higher framerates will be jittery while slower framerates will be smoother. Consider two people, one with a high performance PC and one with a clunker; the former's counter may change too quickly, making it difficult to read, while the latter's will be oddly unresponsive to actual fluctuations in framerate.

## Time-based (Dynamic) Smoothing Factor

What we actually want is the average framerate over the last $T$ duration in some time unit. To do this we will consider that we want our EMA to maintain a constant average age of datapoints $T$, therefore:

$$T = \alpha (0) + (1-\alpha)(T + d_i)$$
$$\alpha = \frac{d_i}{T + d_i}$$

Substituting this into our original formula we get:

$$\bar{d_i} = \frac{d_i}{T + d_i} d_i + (1-\frac{d_i}{T + d_i})\bar{d}_{i-1}$$

And after some simplification:

$$\bar{d}_i = \frac{d_i^2 + \bar{d}_{i-1}T}{T+d_i}$$

So if we want to approximate the smoothing of a duration based SMA like the method arrived at in the original blog, we set $T$ to the SMA window duration divided by two because the average age of time windowed SMA data is simply half the window duration.

## Real World Analysis

I took a random capture of 5 seconds of ARC Raiders gameplay with [CapFrameX](https://www.capframex.com) then implemented assorted smoothing techniques to demonstrate the resulting FPS values.

![](../resources/dyn_sma_ema.png)

In this first graph we compare dynamic SMA (the time-based dynamic queue FPS counter provided by the original post) to our dynamic EMA implementation. What is immediately noticeable is that our EMA persistently outputs lower FPS values than SMA. The reason is that this SMA implementation weights each frame duration over the window period equally; for instance, if you have one very long frame that takes 0.99 seconds preceded by a short frame that takes 0.01 seconds, an unweighted average will tell you that the average frame duration over the previous second was 0.5. To properly compare the two we simply use a weighted average, where each frame duration is weighted by its portion of the window duration.

![](../resources/dyn_wei_sma_ema.png)

This graph provides the most important result that we want to verify, which is that our dynamic EMA FPS counter correctly approximates a comparable dynamic SMA.

![](../resources/fix_sma_ema.png)

Finally, this graph demonstrates that our initial fixed EMA also does a good job at approximating a fixed SMA.

[notebook source](https://github.com/wilgaboury/blog/blob/master/other/fps-analysis/frame_analysis.ipynb)

## FPS Calculation Routine Using SDL

Provided is example C code for using this technique with the popular [SDL library](https://www.libsdl.org/).

```C
void update_ema_frame_duration_sec(
    Uint64 *prev_frame_start,
    float *ema_dur,
    float window_dur
) {
    Uint64 frame_start = SDL_GetPerformanceCounter();
    float frame_dur_unitless = (float)(frame_start-*prev_frame_start);
    *prev_frame_start = frame_start;
    float frame_dur = frame_dur_unitless/(float)SDL_GetPerformanceFrequence();
    float t = window_dur/2.0f;
    *ema_dur = (frame_dur*frame_dur + *ema_dur*t)/(t+frame_dur);
}
```