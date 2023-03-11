{
  :en => {
    :time => {
      :formats => {
        :message_date => lambda { |time, _| "%B #{time.day.ordinalize} at %H:%M" },
        :message_date_with_year => lambda { |time, _| "%B #{time.day.ordinalize} %Y at %H:%M" },
        :message_date_without_time => lambda { |_time, _| "%Y/%m/%d" }
      }
    }
  }
}
