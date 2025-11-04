# frozen_string_literal: true

class Attachment::DemandeItemComponent < ApplicationComponent
  attr_reader :attachment

  def initialize(attachment:)
    @attachment = attachment
  end
end
