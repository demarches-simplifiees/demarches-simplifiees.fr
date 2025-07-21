# frozen_string_literal: true

module SanitizeWithLinkHelper
  def sanitize_with_link(value)
    allowed_tags = Rails.configuration.action_view.sanitized_allowed_tags || []
    tags = allowed_tags + ['a']

    allowed_attributes = Rails.configuration.action_view.sanitized_allowed_attributes || []
    attributes = allowed_attributes + [
      'aria-controls', 'data-fr-opened', 'data-fr-js-modal-button', 'href', 'class'
    ]

    sanitize(value, tags:, attributes:)
  end
end
