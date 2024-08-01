# frozen_string_literal: true

# We monkey patch the DateTimeSelector in order to add accessibility labels
# https://stackoverflow.com/a/47836699
module ActionView
  module Helpers
    class DateTimeSelector
      # Given an ordering of datetime components, create the selection HTML
      # and join them with their appropriate separators.
      def build_selects_from_types(order)
        select = ""
        order.reverse_each do |type|
          separator = separator(type)
          select.insert(0, separator.to_s + send("select_#{type}").to_s)
        end
        # rubocop:disable Rails/OutputSafety
        select.html_safe
        # rubocop:enable Rails/OutputSafety
      end

      def datetime_accessibility_label(n, label)
        prefix_re = @options[:prefix].match('(.*)\[(.*)\]\[(\d+)\]')
        if prefix_re.nil? || prefix_re.size < 2
          prefix = []
        else
          prefix = prefix_re.to_a.drop(1)
        end
        field_for = "#{prefix.join('_')}_#{@options[:field_name]}"

        "<label class='sr-only' for='#{field_for}_#{n}i'>#{label}</label>"
      end

      # Returns the separator for a given datetime component.
      def separator(type)
        return "" if @options[:use_hidden]
        case type
        when :year
          datetime_accessibility_label(1, 'Année')
        when :month
          datetime_accessibility_label(2, 'Mois')
        when :day
          datetime_accessibility_label(3, 'Jour')
        when :hour
          (@options[:discard_year] && @options[:discard_day]) ? "" : @options[:datetime_separator] + datetime_accessibility_label(4, 'Heure')
        when :minute, :second
          @options[:"discard_#{type}"] ? "" : datetime_accessibility_label(5, 'Minute')
        end
      end
    end
  end
end
