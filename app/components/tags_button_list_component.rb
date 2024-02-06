# frozen_string_literal: true

class TagsButtonListComponent < ApplicationComponent
  attr_reader :tags

  def initialize(tags:)
    @tags = tags
  end

  def button_label(tag)
    tag[:libelle].truncate_words(12)
  end

  def button_title(tag)
    tag[:description].presence || tag[:libelle]
  end
end
