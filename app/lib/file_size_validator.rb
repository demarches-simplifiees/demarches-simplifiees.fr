# Source: https://github.com/gitlabhq/gitlabhq/blob/master/lib/file_size_validator.rb
class FileSizeValidator < ActiveModel::EachValidator
  MESSAGES  = { is: :wrong_size, minimum: :size_too_small, maximum: :size_too_big }.freeze
  CHECKS    = { is: :==, minimum: :>=, maximum: :<= }.freeze

  DEFAULT_TOKENIZER = lambda { |value| value.split(//) }
  RESERVED_OPTIONS  = [:minimum, :maximum, :within, :is, :tokenizer, :too_short, :too_long]

  def initialize(options)
    range = options.delete(:in) || options.delete(:within)

    if range.present?
      if !range.is_a?(Range)
        raise ArgumentError, ":in and :within must be a Range"
      end

      options[:minimum], options[:maximum] = range.begin, range.end

      if range.exclude_end?
        options[:maximum] -= 1
      end
    end

    super
  end

  def check_validity!
    keys = CHECKS.keys & options.keys

    if keys.empty?
      raise ArgumentError, 'Range unspecified. Specify the :within, :maximum, :minimum, or :is option.'
    end

    keys.each do |key|
      value = options[key]

      if !(value.is_a?(Integer) && value >= 0) && !value.is_a?(Symbol)
        raise ArgumentError, ":#{key} must be a nonnegative Integer or symbol"
      end
    end
  end

  def validate_each(record, attribute, value)
    if !value.kind_of? CarrierWave::Uploader::Base
      raise(ArgumentError, "A CarrierWave::Uploader::Base object was expected")
    end

    if value.kind_of?(String)
      value = (options[:tokenizer] || DEFAULT_TOKENIZER).call(value)
    end

    CHECKS.each do |key, validity_check|
      if !check_value = options[key]
        next
      end

      check_value =
        case check_value
        when Integer
          check_value
        when Symbol
          record.send(check_value)
        end

      if key == :maximum
        value ||= []
      end

      value_size = value.size
      if value_size.send(validity_check, check_value)
        next
      end

      errors_options = options.except(*RESERVED_OPTIONS)
      errors_options[:file_size] = help.number_to_human_size check_value

      default_message = options[MESSAGES[key]]
      if default_message
        errors_options[:message] ||= default_message
      end

      record.errors.add(attribute, MESSAGES[key], errors_options)
    end
  end

  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::NumberHelper
  end
end
