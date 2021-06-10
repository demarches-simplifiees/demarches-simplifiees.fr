module AutoStripConcern
  extend ActiveSupport::Concern

  class_methods do
    # NOTE: inspired by https://rubygems.org/gems/auto_strip_attributes
    def auto_strip_attributes(*attributes, **options)
      opts = Hash(options).symbolize_keys
      delete_whitespaces = opts.fetch(:delete_whitespaces, false)
      squish = opts.fetch(:squish, false)

      attributes.each do |attr|
        before_validation do |record|
          value = record[attr]
          value.gsub!(/[[:space:]]+/, ' ') if squish && value.respond_to?(:gsub!)
          value.delete!(" \t") if delete_whitespaces && value.respond_to?(:delete!)
          value.strip! if value.respond_to?(:strip!)
          record[attr] = value
        end
      end
    end
  end
end
