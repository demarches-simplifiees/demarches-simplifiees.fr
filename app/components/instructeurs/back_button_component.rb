# frozen_string_literal: true

class Instructeurs::BackButtonComponent < ApplicationComponent
  def initialize(to:)
    @to = to
  end

  def call
    link_to "", @to, class: 'back-btn fr-btn fr-btn--secondary fr-btn--sm fr-mr-2w fr-icon-arrow-left-line', title: t('.back')
  end
end
