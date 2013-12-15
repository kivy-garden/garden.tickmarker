TickMarker
==========

tickmarker exports the `TickMarker` widget, which places ticks in the center
of the widget so that when combined with another widget e.g. a slider it
marks intervals. TickMarker supports horizontal and vertical orientation,
minor/major ticks and log10 representation.

For example, to create a log slider from 0.1 to 10 starting at 1 with
major tick marks at every decade, and minor ticks at every 0.2 decades:

    from kivy.uix.slider import Slider
    from kivy.garden.tickmarker import TickMarker
    class TickSlider(Slider, TickMarker):
    pass
    s = TickSlider(log=True, min_log=.1, max_log=10, value_log=1,
    ticks_major=1, ticks_minor=5)

Or a linear slider from 10 to 200 starting at 60 with major tick marks at
every 50 units from start, and minor ticks at every 10 units

    s = TickSlider(min=10, max=200, value=60, ticks_major=50, ticks_minor=5)


To create a log progress bar from 10 to 1000 starting at 500 with major tick
marks at every decade, and minor ticks at every 0.1 decades::

    from kivy.uix.progressbar import ProgressBar
    from kivy.garden.tickmarker import TickMarker
    class TickBar(ProgressBar, TickMarker):
    padding = NumericProperty(0)
    min = NumericProperty(0)
    orientation = OptionProperty('horizontal', options=('horizontal'))
    s = TickBar(log=True, min_log=10, max_log=1000, value_log=500,
    ticks_major=1, ticks_minor=10)

When combining with another widget such as a slider, the widget must have
min, max, value, orientation, and padding fields. See the second example above
as to how you would do this with a ProgressBar. When logarithmic representation
is required you read and write to the numerical fields using `min_log`,
`max_log` and `value_log` instead of `min`, `max`, and `value`.
