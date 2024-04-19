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

  def each_category
    tags.each_pair do |category, tags|
      yield category, tags, can_toggle_nullable?(category)
    end
  end

  private

  def can_toggle_nullable?(category)
    return false if category != :champ_public

    tags[category].any? { _1[:maybe_null] }
  end
end
