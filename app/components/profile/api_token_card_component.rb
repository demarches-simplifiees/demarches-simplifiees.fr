# frozen_string_literal: true

class Profile::APITokenCardComponent < ApplicationComponent
  private

  def render?
    current_administrateur.present?
  end

  def api_tokens
    current_administrateur.api_tokens.order(created_at: :desc)
  end
end
