# frozen_string_literal: true

{
  :fr => {
    :time => {
      :formats => {
        veryshort: lambda { |time, _|
          if time.year == Date.current.year
            "%d/%m %H:%M"
          else
            "%d/%m/%Y %H:%M"
          end
        },
        :message_date => lambda { |time, _| "le #{time.day == 1 ? '1er' : time.day} %B à %H h %M" },
        :message_date_with_year => lambda { |time, _| "le #{time.day == 1 ? '1er' : time.day} %B %Y à %H h %M" },
        :message_date_without_time => lambda { |_time, _| "%d/%m/%Y" }
      }
    },

    date: {
      formats: {
        default: "%d %B %Y"
      }
    },

    datetime: {
      distance_in_words: {
        x_weeks: {
          one: "1 semaine",
          other: "%{count} semaines"
        }
      }
    }
  }
}
