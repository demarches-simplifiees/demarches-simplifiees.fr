# frozen_string_literal: true

class Instructeurs::BackButtonComponent < ApplicationComponent
  def initialize(to:)
    @to = to
  end

  def call
    link_to @to, class: 'fr-btn fr-btn--secondary fr-btn--sm fr-mr-3w back-btn', aria: { label: t('.back') } do
      dsfr_icon('fr-icon-arrow-left-line', aria: { hidden: true })
    end
  end
end
