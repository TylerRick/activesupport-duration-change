# ActiveSupport::Duration#change  [![Gem Version](https://badge.fury.io/rb/activesupport-duration-change.svg)](https://badge.fury.io/rb/activesupport-duration-change)

Change/manipulate [ActiveSupport::Duration](https://api.rubyonrails.org/classes/ActiveSupport/Duration.html) objects with these added methods:

# API

## `#change`, `#change_cascade`

```ruby
(9.hours + 10.minutes + 40.seconds).change(hours: 12)             #=> 12 hours, 10 minutes, and 40 seconds
(9.hours + 10.minutes + 40.seconds).change(hours: 12, minutes: 5) #=> 12 hours, 5 minutes, and 40 seconds
(9.hours + 10.minutes + 40.seconds).change(minutes: 5)            #=> 9 hours, 5 minutes, and 40 seconds

(9.hours + 10.minutes + 40.seconds).change_cascade(hours: 12)  # => 12 hours
(9.hours + 10.minutes + 40.seconds).change_cascade(minutes: 5) # => 9 hours and 5 minutes
```

## `#normalize`

```ruby
90.seconds.normalize                          #=> 1 minute and 30 seconds
23.hours + 59.minutes + 60.seconds).normalize #=> 1 day
```

## `#round`

```ruby
30.seconds.round(:minutes)        #=> 1 minute
89.seconds.round(:minutes)        #=> 1 minute
90.seconds.round(:minutes)        #=> 2 minutes
(1.hour + 30.seconds).round(:minutes)  #=> 1 hour and 1 minute

2.5.seconds.round                 #=> 3 seconds
2.5.seconds.round(half: :down)    #=> 2 seconds
```

## `#truncate`

```ruby
30.seconds.truncate(:minutes)      #=> 0 seconds

# This could be surprising, but remember that it just looks at the values as they exist in each part.
90.seconds.truncate(:minutes)      #=> 0 seconds

# If needed, you can always normalize the duration first...
90.seconds.normalize                    #=> 1 minute and 30 seconds
90.seconds.normalize.truncate(:minutes) #=> 1 minute
```

## .from_parts

```ruby
# This is the inverse of #parts.
duration = ActiveSupport::Duration.from_parts({hours: 9, minutes: 10, seconds: 40})
```

# Installation

Add this line to your application's Gemfile:

```ruby
gem 'activesupport-duration-change'
```

# See also

- [activesupport-duration-human_string](https://github.com/TylerRick/activesupport-duration-human_string), which lets you convert `Duration` objects to human-friendly strings like '2h 30m 17s'

# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

# Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TylerRick/activesupport-duration-change.
