# frozen_string_literal: true

class Dsfr::CardVerticalComponent < ApplicationComponent
  renders_many :footer_buttons

  attr_reader :title, :desc, :tags, :error

  def initialize(title: nil, desc: nil, tags: nil, error: nil)
    @title = title
    @desc = desc
    @tags = tags
    @error = error
  end
end
