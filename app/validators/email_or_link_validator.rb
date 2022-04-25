class EmailOrLinkValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    URI.parse(value)
  rescue URI::InvalidURIError
    record.errors.add(attribute, :invalid_uri_or_email)
  end
end
