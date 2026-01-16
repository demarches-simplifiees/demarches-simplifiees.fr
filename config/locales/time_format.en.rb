# frozen_string_literal: true

{
  :en => {
    :time => {
      :formats => {
        veryshort: lambda { |time, _|
          if time.year == Date.current.year
            "%-d %b %H:%M"
          else
            "%-d %b %Y %H:%M"
          end
        },
        :message_date => lambda { |time, _| "%B #{time.day.ordinalize} at %H:%M" },
        :message_date_with_year => lambda { |time, _| "%B #{time.day.ordinalize} %Y at %H:%M" },
        :message_date_without_time => lambda { |_time, _| "%Y/%m/%d" },
      },
    },

    datetime: {
      distance_in_words: {
        x_weeks: {
          one: "1 week",
          other: "%{count} weeks",
        },
      },
    },
  },
}
