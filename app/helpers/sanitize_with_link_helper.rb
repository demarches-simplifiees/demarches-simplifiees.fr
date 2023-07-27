module SanitizeWithLinkHelper
  def sanitize_with_link(value)
    tags = Rails.configuration.action_view.sanitized_allowed_tags + ['a']
    sanitize(value, tags:)
  end
end
