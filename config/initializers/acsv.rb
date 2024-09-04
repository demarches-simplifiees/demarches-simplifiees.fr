# frozen_string_literal: true

require 'csv'

# PR : https://github.com/wvengen/ruby-acsv/pull/3
module ACSV
  class CSV < ::CSV
    def self.new_for_ruby3(data, options = {})
      options[:col_sep] ||= ACSV::Detect.separator(data) || :auto
      # because of the Separation of positional and keyword arguments in Ruby 3.0
      # (https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/)
      # instead of
      # super(data, options)
      # we do
      ::CSV.new(data, **options)
    end
  end
end
