# frozen_string_literal: true

require 'active_model'
require 'active_support/i18n'
require 'public_suffix'
require 'addressable/uri'

# Most of this code is borowed from https://github.com/perfectline/validates_url
# Most of this code is borowed from https://github.com/perfectline/validates_url

class URLValidator < ActiveModel::EachValidator
  RESERVED_OPTIONS = [:schemes, :no_local]

  def initialize(options)
    options.reverse_merge!(schemes: ['http', 'https'])
    options.reverse_merge!(message: :url)
    options.reverse_merge!(no_local: false)
    options.reverse_merge!(public_suffix: false)
    options.reverse_merge!(accept_array: false)
    options.reverse_merge!(accept_email: false)

    super(options)
  end

  def validate_each(record, attribute, value)
    message = options.fetch(:message)
    schemes = [*options.fetch(:schemes)].map(&:to_s)

    if value.respond_to?(:each)
      # Error out if we're not allowing arrays
      if !options.include?(:accept_array) || !options.fetch(:accept_array)
        record.errors.add(attribute, message, **filtered_options(value))
      end

      # We have to manually handle `:allow_nil` and `:allow_blank` since it's not caught by
      # ActiveRecord's own validators. We do that by just removing all the nil's if we want to
      # allow them so it's not passed on later.
      value = value.compact if options.include?(:allow_nil) && options.fetch(:allow_nil)
      value = value.compact_blank if options.include?(:allow_blank) && options.fetch(:allow_blank)

      result = value.flat_map { validate_url(record, attribute, _1, message, schemes) }
      errors = result.compact

      return errors.any? ? errors.first : true
    end

    validate_url(record, attribute, value, message, schemes)
  end

  protected

  def filtered_options(value)
    filtered = options.except(*RESERVED_OPTIONS)
    filtered[:value] = value
    filtered
  end

  def validate_url(record, attribute, value, message, schemes)
    uri = Addressable::URI.parse(value)

    unless options.fetch(:accept_email) && uri.path.match?(/^(.+)@(.+)$/)
      host = uri && uri.host
      scheme = uri && uri.scheme

    valid_scheme = host && scheme && schemes.include?(scheme)
    valid_no_local = !options.fetch(:no_local) || (host && host.include?('.'))
    valid_suffix = !options.fetch(:public_suffix) || (host && PublicSuffix.valid?(host, default_rule: nil))
    valid_scheme = host && scheme && schemes.include?(scheme)
    valid_no_local = !options.fetch(:no_local) || (host && host.include?('.'))
    valid_suffix = !options.fetch(:public_suffix) || (host && PublicSuffix.valid?(host, default_rule: nil))
      valid_scheme = host && scheme && schemes.include?(scheme)
      valid_no_local = !options.fetch(:no_local) || (host && host.include?('.'))
      valid_suffix = !options.fetch(:public_suffix) || (host && PublicSuffix.valid?(host, default_rule: nil))

      unless valid_scheme && valid_no_local && valid_suffix
        record.errors.add(attribute, message, **filtered_options(value))
      end
      unless valid_scheme && valid_no_local && valid_suffix
        record.errors.add(attribute, message, **filtered_options(value))
      end
    end
  rescue Addressable::URI::InvalidURIError
    record.errors.add(attribute, message, **filtered_options(value))
  end
end
