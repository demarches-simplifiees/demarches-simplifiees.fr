{
  :fr => {
    :time => {
      :formats => {
        :message_date => lambda { |time, _| "le #{time.day == 1 ? '1er' : time.day} %B à %H h %M" },
        :message_date_with_year => lambda { |time, _| "le #{time.day == 1 ? '1er' : time.day} %B %Y à %H h %M" }
      }
    }
  }
}
