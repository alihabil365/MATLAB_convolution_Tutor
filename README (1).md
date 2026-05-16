# Graphical Convolution Tutor

An interactive MATLAB GUI for learning **graphical convolution** through animation, shaded overlap areas, and step-by-step explanations.

This project helps students visualize the convolution process:

\[
y(t) = \\int f(\\tau)g(t - \\tau),d\\tau
]

Instead of treating convolution as only a formula, the app shows how one signal is flipped, shifted, multiplied, and integrated to build the output signal point by point.

## Preview

The app displays three synchronized plots:

1. **Signals in the (\\tau)-domain**  
Shows (f(\\tau)) and the flipped/shifted signal (g(t - \\tau)).
2. **Overlap product**  
Shows the shaded product (f(\\tau)g(t - \\tau)), where the shaded area becomes the current output value.
3. **Convolution output**  
Shows the growing output curve (y(t)) as the animation moves forward.

## Features

* Interactive MATLAB GUI built with `uifigure`, `uigridlayout`, `uiaxes`, sliders, buttons, and dropdown controls
* Animated visualization of graphical convolution
* Preset signal pairs:

  * Rect x Rect
  * Rect x Triangle
  * Exp Decay x Rect
  * Two Triangles
  * Custom slider signals
* Adjustable signal amplitude and width controls
* Play, pause, step forward, step back, restart, and full-output controls
* Slider-based manual control over the current time value
* Built-in explanations for each convolution step
* Modern dark interface
* No external files required
* No additional MATLAB toolboxes required

## Learning Goal

The main goal of this app is to make convolution feel visual and intuitive.

At each value of (t), the app performs the graphical convolution process:

1. Start with (f(\\tau)) and (g(\\tau))
2. Flip (g(\\tau)) to get (g(-\\tau))
3. Shift it to get (g(t - \\tau))
4. Multiply (f(\\tau)) by (g(t - \\tau))
5. Integrate the shaded product area
6. Plot that area as one point of (y(t))

## Requirements

* MATLAB R2023a or newer
* No external toolboxes
* No external data files

## Installation

Clone this repository:

```bash
git clone https://github.com/YOUR-USERNAME/GraphicalConvolutionTutor.git
cd GraphicalConvolutionTutor
```

Open MATLAB and make sure the project folder is on the MATLAB path.

## How to Run

The main file must be named:

```text
GraphicalConvolutionTutor.m
```

If your downloaded file is named something like:

```text
GraphicalConvolutionTutor (1).m
```

rename it to:

```text
GraphicalConvolutionTutor.m
```

Then run this command in the MATLAB Command Window:

```matlab
GraphicalConvolutionTutor
```

## How to Use

1. Choose a signal pair from the preset dropdown.
2. Press **Play** to animate the convolution.
3. Watch how (g(t - \\tau)) slides across (f(\\tau)).
4. Observe the shaded product area.
5. Notice how the output (y(t)) grows point by point.
6. Use **Step Forward** and **Step Back** to slow down the process.
7. Try the sliders to change amplitude and width.
8. Use **Max Overlap** to jump to the largest overlap region.
9. Use **Full Output** to display the completed convolution curve.

## Signal Presets

|Preset|What it demonstrates|
|-|-|
|Rect x Rect|Two rectangular pulses convolving into a triangular output|
|Rect x Triangle|A rectangular window sliding across a triangular signal|
|Exp Decay x Rect|A causal exponential averaged through a rectangular window|
|Two Triangles|Smooth convolution from two gradually changing signals|
|Custom slider signals|User-adjustable pulse combinations using sliders|

## Why Convolution Matters

Convolution appears in many engineering, science, and signal processing applications:

* Audio reverb and echo modeling
* Circuit system response
* Image filtering, blurring, and sharpening
* Biomedical signal processing such as ECG and EEG filtering
* Communications channels and signal distortion
* Linear time-invariant system analysis

## Notes

* The app computes convolution numerically using `trapz`.
* The shifted signal (g(t - \\tau)) is generated with interpolation.
* The project is designed for teaching and visualization rather than symbolic convolution.
* The GUI is self-contained in one MATLAB file.

## Author

Created as an educational MATLAB tool for visualizing graphical convolution.

