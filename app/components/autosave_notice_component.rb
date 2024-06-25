# frozen_string_literal: true

class AutosaveNoticeComponent < ApplicationComponent
  attr_reader :label_scope

  def initialize(success:, label_scope:)
    @success = success
    @label_scope = label_scope
  end

  def success? = @success

  def label
    success? ? t(".#{label_scope}.saved") : t(".#{label_scope}.error")
  end
end
