# frozen_string_literal: true

module Sanitizers
  class MailScrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = Rails.application.config.action_view.sanitized_allowed_tags + ['a', 'img']
    end

    def skip_node?(node)
      node.text?
    end
  end
end
