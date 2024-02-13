require 'active_support'
require 'active_support/duration'
require 'active_support/duration/iso8601_serializer'

module ActiveSupport
  class Duration
    # Convert [ActiveSupport::Duration](https://api.rubyonrails.org/classes/ActiveSupport/Duration.html)
    # objects to human-friendly strings like `'2h 30m 17s'` or `'3y 6m 4d 12h 30m 5s'`.
    #
    # - Like [`distance_of_time_in_words`](https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html) helper but _exact_ rather than approximate.
    # - Like [`#inspect`](https://github.com/rails/rails/blob/b9ca94caea2ca6a6cc09abaffaad67b447134079/activesupport/lib/active_support/duration.rb#L372) but more concise and configurable.
    # - Like [`#iso8601`](https://api.rubyonrails.org/classes/ActiveSupport/Duration.html#method-i-iso8601) but more human readable rather than machine readable.
    #
    # Note that the unit 'm' is used for both months and minutes.
    #
    # ## Examples
    #
    # ```ruby
    # duration = 3500.seconds
    # duration.human_str                 # =>  '58m 20s'
    # duration.human_str(delimiter: '')  # =>  '58m20s'
    # duration.human_str(separator: ' ') # =>  '58 m 20 s'
    # duration.human_str(delimiter: ', ', separator: ' ') # =>  '58 m, 20 s'
    #
    # duration = ActiveSupport::Duration.parse "P3Y6M4DT12H30M5S"
    # # => 3 years, 6 months, 4 days, 12 hours, 30 minutes, and 5 seconds
    #
    # duration.human_str                  # => "3y 6m 4d 12h 30m 5s"
    # (duration - 4.days).human_str       # => "3y 6m 12h 30m 5s"
    # duration.human_str(delimiter: ', ') # => "3y, 6m, 4d, 12h, 30m, 5s"
    # ```
    #
    # ## Options
    #
    # `:precision`: Precision of seconds (defaults to nil, which is no digits after decimal).
    #
    # `:separator`: The separator between the digits and units (defaults to '', giving for example '3h' with nothing between them).
    #
    # `:delimiter`: The delimiter between different parts like minutes and seconds (defaults to ' ').
    #
    # `use_2_digit_numbers`: Set to true if you want to pad 1-digit nubers to 2 digits ('3h 05m 07s'
    # instead of '3h 5m 7s'). Never pads the first part of the duration, only later parts.
    #
    def human_str(precision: nil, separator: '', delimiter: ' ', use_2_digit_numbers: false)
      HumanStringSerializer.new(
        self.class.build(value),
        precision: precision,
        separator: separator,
        delimiter: delimiter,
        use_2_digit_numbers: use_2_digit_numbers,
      ).serialize
    end
    alias_method :human_string, :human_str
    alias_method :to_human_s, :human_str
  end
end

module ActiveSupport
  class Duration
    # Based on: active_support/duration/iso8601_serializer.rb
    # Inherits: #normalize
    class HumanStringSerializer < ISO8601Serializer
      def initialize(duration, precision: nil, separator: '', delimiter: ' ', use_2_digit_numbers: false)
        @duration            = duration
        @precision           = precision
        @separator           = separator
        @delimiter           = delimiter
        @use_2_digit_numbers = use_2_digit_numbers
      end

      # Builds and returns output_parts string.
      def serialize
        parts, sign = normalize

        output_parts = []
        output_parts << [parts[:years],   'y'] if parts.key?(:years)
        output_parts << [parts[:months],  'm'] if parts.key?(:months)
        output_parts << [parts[:weeks],   'w'] if parts.key?(:weeks)
        output_parts << [parts[:days],    'd'] if parts.key?(:days)
        output_parts << [parts[:hours],   'h'] if parts.key?(:hours)
        output_parts << [parts[:minutes], 'm'] if parts.key?(:minutes)
        if parts.key?(:seconds)
          output_parts << [sprintf(@precision ? "%0.0#{@precision}f" : '%g', parts[:seconds]), 's']
        end

        output_parts.map!.with_index { |(n, units), i|
          if @use_2_digit_numbers && i >= 1
            n = sprintf('%02d', n)
          end
          "#{n}#{@separator}#{units}"
        }

        output = output_parts.join(@delimiter)
        "#{sign}#{output}"
      end
    end
  end
end
