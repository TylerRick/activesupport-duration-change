require 'active_support/duration'

module ActiveSupport
  class Duration
    class << self
      # Creates a new Duration from a Hash of parts (inverse of Duration#parts).
      #
      # Surprising that upstream ActiveSupport doesn't provide this method
      #
      # normalize: true (the default) changes 30.5m into 30m, 30s, for example.
      def from_parts(parts, normalize: true)
        parts = parts.compact.reject { |k, v| v.zero? }
        duration = new(calculate_total_seconds(parts), parts)
        if normalize
          duration.normalize
        else
          duration
        end
      end

      alias parse_parts from_parts

      def units_largest_first
        # Reverse since PARTS_IN_SECONDS is ordered smallest to largest
        PARTS_IN_SECONDS.keys.reverse.freeze
      end

      def next_smaller_unit(unit)
        i = PARTS.index(unit) or raise(ArgumentError, "unknown unit #{unit}")
        PARTS[i + 1]
      end

      def smaller_units(unit)
        # The index of unit; we only want parts with indexes > this index
        unit_i = units_largest_first.index(unit) or raise(ArgumentError, "unknown unit #{unit}")
        units_largest_first.select.with_index { |key, i| i > unit_i }
      end
    end

    # Re-builds the Duration using build(value). Useful if you may have "extra" seconds, minutes,
    # etc. that could be carried over to the next higher unit, such as if you've built a Duration
    # using Duration.seconds and a number of seconds > 60.
    #
    # ActiveSupport::Duration.seconds(61).normalize
    # => 1 minute and 1 second
    #
    def normalize
      Duration.build(value)
    end

    # Replaces parts of duration with given part values. Unlike #change_cascade and Time#change,
    # *only* ever changes the given parts; it does *not* reset any smaller-unit parts.
    def change(**changes)
      self.class.from_parts(
        parts.merge(changes),
        normalize: false
      )
    end

    # Changes the given part(s) of the duration and resets any smaller parts.
    #
    # @example
    #   (9.hours + 10.minutes + 40.seconds).change_cascade(hours: 12)
    #   (9.hours + 10.minutes + 40.seconds).change_cascade(minutes: 5)
    #   => 9 hours and 5 minutes
    #
    # Similar to Time#change
    # But note that the keys are plural, so :years instead of :year.
    # Should we allow key aliases? Should we raise ArgumentError if key not recognized? Yes. (Why doesn't Time#change?)
    # or should this be named truncate? or change_reset_smaller_parts?
    #
    #-----------
    # Returns a new Duration where one or more of the elements have been changed according
    # to the +options+ parameter. The time options (<tt>:hour</tt>, <tt>:min</tt>,
    # <tt>:sec</tt>, <tt>:usec</tt>, <tt>:nsec</tt>) reset cascadingly, so if only
    # the hour is passed, then minute, sec, usec and nsec is set to 0. If the hour
    # and minute is passed, then sec, usec and nsec is set to 0. The +options+ parameter
    # takes a hash with any of these keys: <tt>:year</tt>, <tt>:month</tt>, <tt>:day</tt>,
    # <tt>:hour</tt>, <tt>:min</tt>, <tt>:sec</tt>, <tt>:usec</tt>, <tt>:nsec</tt>,
    # <tt>:offset</tt>. Pass either <tt>:usec</tt> or <tt>:nsec</tt>, not both.
    #
    #   Time.new(2012, 8, 29, 22, 35, 0).change(day: 1)              # => Time.new(2012, 8, 1, 22, 35, 0)
    #   Time.new(2012, 8, 29, 22, 35, 0).change(year: 1981, day: 1)  # => Time.new(1981, 8, 1, 22, 35, 0)
    #   Time.new(2012, 8, 29, 22, 35, 0).change(year: 1981, hour: 0) # => Time.new(1981, 8, 29, 0, 0, 0)
    def change_cascade(options)
      options.assert_valid_keys(*PARTS_IN_SECONDS, :nsec, :usec)

      reset = false
      new_parts = {}
      new_parts[:years]   = options.fetch(:years,               parts[:years])  ; reset ||= options.key?(:years)
      new_parts[:months]  = options.fetch(:months,  reset ? 0 : parts[:months]) ; reset ||= options.key?(:months)
      new_parts[:days]    = options.fetch(:days,    reset ? 0 : parts[:days])   ; reset ||= options.key?(:days)
      new_parts[:hours]   = options.fetch(:hours,   reset ? 0 : parts[:hours])  ; reset ||= options.key?(:hours)
      new_parts[:minutes] = options.fetch(:minutes, reset ? 0 : parts[:minutes]); reset ||= options.key?(:minutes)
      new_parts[:seconds] = options.fetch(:seconds, reset ? 0 : parts[:seconds])

      if new_nsec = options[:nsec]
        raise ArgumentError, "Can't change both :nsec and :usec at the same time: #{options.inspect}" if options[:usec]
        new_usec = Rational(new_nsec, 1000)
      else
        new_usec = nil
#        new_usec = options.fetch(:usec, (options[:hour] || options[:min] || options[:sec]) ? 0 :
#                                         Rational(nsec, 1000))
      end
      if new_usec
        raise ArgumentError, "argument out of range" if new_usec >= 1000000

        new_parts[:seconds] += Rational(new_usec, 1000000)
      end

      self.class.from_parts(
        new_parts.compact.reject { |k, v| v.zero? },
        normalize: false,
      )
    end


    # Returns duration rounded to the nearest value having a precision of `precision`, which is a
    # unit such as :hours, which would mean "round to the nearest hour". The smaller parts (:minutes
    # and :seconds in this example) are turned into a fraction of the requested precision (:hours),
    # which is then added to requested precision part. Finally, `round` is called on the requested
    # precision part (hours in this example).
    #
    # If optional [ndigits] [, half: mode] arguments are supplied, they are passed along to
    # [round](https://ruby-doc.org/core/Float.html#method-i-round).
    #
    # @example
    #   30.seconds.round(:minutes)        #=> 1 minute
    #   89.seconds.round(:minutes)        #=> 1 minute
    #   90.seconds.round(:minutes)        #=> 2 minutes
    #
    #   2.5.seconds.round                 #=> 3 seconds
    #   2.5.seconds.round(half: :down)    #=> 2 seconds
    #
    # @raises ArgumentError
    # TODO raise ArgumentError if precision not recognized as a unit
    #
    def round(precision = smallest_unit, *args, **opts)
      #puts "Rounding #{parts.inspect} (in particular #{parts[precision]} #{precision}) to nearest #{precision.inspect}"

      new_part_value = orig_part_value = (parts[precision] || 0)
      fraction = smaller_parts_to_fraction_of(precision)
      # Usually fraction is in the range 0..1, unless the smaller units are overflowed (non-normalized)
      new_part_value += fraction
      #puts "Adding #{orig_part_value} + fraction parts #{fraction.inspect} (#{fraction.to_f}) = #{new_part_value} (#{new_part_value.to_f})"

      new_part_value = new_part_value.round(*args, **opts)

      change_cascade(
        precision => new_part_value
      )
    end

    # Convert the parts that are smaller than `unit` to be a fraction (Rational) of that
    # `unit`.
    #
    # For example, if `unit` is :hours and self is 1h 29m 60s, then it would look at the parts
    # smaller than hour, 29m 60s, which is the same as 30m, and would convert that to a fraction of
    # hours, which would be 30m/60m = 1/2r.
    #
    def smaller_parts_to_fraction_of(unit)
      #next_smaller_unit = self.class.next_smaller_unit(unit)
      #next_smaller_unit_in_s = ActiveSupport::Duration::PARTS_IN_SECONDS[next_smaller_unit] # 1 if unit == :minutes
      #puts %(unit_in_s=#{(unit_in_s).inspect}, next_smaller_unit_in_s=#{(next_smaller_unit_in_s).inspect})

      smaller_parts = smaller_parts(unit)
      numerator_s = ActiveSupport::Duration.send(:calculate_total_seconds, smaller_parts)
      denominator_s = ActiveSupport::Duration::PARTS_IN_SECONDS[unit] # 60 if unit == :minutes

      fraction = Rational(numerator_s, denominator_s)
      #puts "#{smaller_parts.inspect} converted to  fraction #{numerator_s}/#{denominator_s} = #{fraction} (#{fraction.to_f})"
      fraction
    end

    # Returns all parts than `unit` as a Hash that is a subset of self.parts.
    #
    # For example, if `unit` is :hours and self is 1h 29m 60s, then it would return the parts
    # smaller than hour, 29m 60s, as the hash { minutes: 29, seconds: 60 }.
    #
    def smaller_parts(unit)
      parts.slice *ActiveSupport::Duration.smaller_units(unit)
    end

    def smallest_part
      [parts.to_a.last].to_h
    end

    def smallest_unit
      parts.to_a.last[0]
    end

    # Truncates the Duration to the specified precision. All smaller parts are discarded.
    #
    # Similar to https://ruby-doc.org/core-2.7.1/Float.html#method-i-truncate
    #
    def truncate(precision = smallest_unit, *args, **opts)
      #puts %(Truncating #{parts.inspect} to #{precision.inspect})

      # TODO: only use truncate here if :seconds or if part is Float ?
      # or just always pass them along, although they are probably only needed for :seconds
      part_value = (parts[precision] || 0)
      new_part_value = part_value.truncate(*args)
      change_cascade(
        precision => new_part_value
      )
    end

    # TODO: For completeness to complement truncate:
    # https://ruby-doc.org/3.2.2/Float.html#method-i-ceil
    # https://ruby-doc.org/3.2.2/Rational.html#method-i-round
#    def ceil
#    end

#    def floor
#    end

  end
end
