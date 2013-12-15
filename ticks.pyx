#cython: cdivision=True

from kivy import metrics
from decimal import Decimal

cdef extern from "math.h" nogil:
    double ceil(double)
    double floor(double)
    double log10(double)
    double pow(double base, double exponent)


def compute_ticks(list indices, list vertices, int ticks_minor,
                  double ticks_major, double padding, double s_max,
                  double s_min, int log, int horizontal, tuple size,
                  tuple pos):
    cdef int n_ticks, k, m, s_min_low, start_dec, count_min, count, pos_dec_low
    cdef int zero, above, below, dist1, dist2
    cdef double n_decades, decade_dist, min_pos, pos_dec, diff, pos_log
    cdef double tick_dist, center, axis_dist, start, maj_plus, maj_minus
    cdef double min_plus, min_minus, n_ticks_t
    cdef list points
    if log:
        # count the decades in min - max. This is in actual decades,
        # not logs.
        n_decades = floor(s_max - s_min)
        # for the fractional part of the last decade, we need to
        # convert the log value, x, to 10**x but need to handle
        # differently if the last incomplete decade has a decade
        # boundary in it
        if floor(s_min + n_decades) != floor(s_max):
            n_decades += 1 - (pow(10, (s_min + n_decades + 1)) - pow(10,
                              s_max)) / pow(10, floor(s_max + 1))
        else:
            n_decades += ((pow(10, s_max) - pow(10, (s_min + n_decades))) /
                          pow(10, floor(s_max + 1)))
        # this might be larger than what is needed, but we delete
        # excess later
        n_ticks_t = n_decades / float(ticks_major)
        n_ticks = int(floor(n_ticks_t * (ticks_minor if ticks_minor >=
                                         1 else 1))) + 2
        # in decade multiples, e.g. 0.1 of the decade, the distance
        # between ticks
        decade_dist = ticks_major / float(ticks_minor if
                                          ticks_minor else 1.0)

        points = [0] * n_ticks
        points[0] = (0., True)  # first element is always a major tick
        k = 1  # position in points
        # because each decade is missing 0.1 of the decade, if a tick
        # falls in < min_pos skip it
        min_pos = 0.1 - 0.00001 * decade_dist
        s_min_low = int(floor(s_min))
        # first real tick location. value is in fractions of decades
        # from the start we have to use decimals here, otherwise
        # floating point inaccuracies results in bad values
        start_dec = int(ceil((10 ** Decimal(s_min - s_min_low - 1)) /
                             Decimal(decade_dist)) * decade_dist)
        count_min = (0 if not ticks_minor else
                     int(floor(start_dec / decade_dist)) % ticks_minor)
        start_dec += s_min_low
        count = 0  # number of ticks we currently have passed start
        while True:
            # this is the current position in decade that we are.
            # e.g. -0.9 means that we're at 0.1 of the 10**ceil(-0.9)
            # decade
            pos_dec = start_dec + decade_dist * count
            pos_dec_low = int(floor(pos_dec))
            diff = pos_dec - pos_dec_low
            zero = abs(diff) < 0.001 * decade_dist
            if zero:
                # the same value as pos_dec but in log scale
                pos_log = pos_dec_low
            else:
                pos_log = log10((pos_dec - pos_dec_low
                                 ) * pow(10, ceil(pos_dec)))
            if pos_log > s_max:
                break
            count += 1
            if zero or diff >= min_pos:
                points[k] = (pos_log - s_min, ticks_minor
                             and not count_min % ticks_minor)
                k += 1
            count_min += 1
        del points[k:]
        n_ticks = len(points)
    else:
        # distance between each tick
        tick_dist = ticks_major / float(ticks_minor if
                                        ticks_minor else 1.0)
        n_ticks = int(floor((s_max - s_min) / tick_dist) + 1)

    count = len(indices) // 2
    # adjust mesh size
    if count > n_ticks:
        del vertices[n_ticks * 8:]
        del indices[n_ticks * 2:]
    elif count < n_ticks:
            vertices.extend([0] * (8 * (n_ticks - count)))
            indices.extend(range(2 * count, 2 * n_ticks))

    if horizontal:
        center = pos[1] + size[1] / 2.0
        axis_dist = size[0]
        start = pos[0] + padding
        above, below, dist1, dist2 = 1, 5, 0, 4
    else:
        center = pos[0] + size[0] / 2.0
        axis_dist = size[1]
        start = pos[1] + padding
        above, below, dist1, dist2 = 0, 4, 1, 5
    # now, the physical distance between ticks
    tick_dist = (axis_dist - 2 * padding
                 ) / float(s_max - s_min) * (tick_dist if not log
                                             else 1.0)
    # amounts that ticks extend above/below axis
    maj_plus = center + metrics.dp(12)
    maj_minus = center - metrics.dp(12)
    min_plus = center + metrics.dp(6)
    min_minus = center - metrics.dp(6)

    if log:
        for k in range(n_ticks):
            m = k * 8
            vertices[m + dist1] = start + points[k][0] * tick_dist
            vertices[m + dist2] = vertices[m + dist1]
            if not points[k][1]:
                vertices[m + above] = min_plus
                vertices[m + below] = min_minus
            else:
                vertices[m + above] = maj_plus
                vertices[m + below] = maj_minus
    else:
        for k in range(n_ticks):
            m = k * 8
            vertices[m + dist1] = start + k * tick_dist
            vertices[m + dist2] = vertices[m + dist1]
            if ticks_minor and k % ticks_minor:
                vertices[m + above] = min_plus
                vertices[m + below] = min_minus
            else:
                vertices[m + above] = maj_plus
                vertices[m + below] = maj_minus
