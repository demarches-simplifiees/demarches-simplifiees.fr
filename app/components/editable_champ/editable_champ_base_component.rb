# frozen_string_literal: true

class EditableChamp::EditableChampBaseComponent < ApplicationComponent
  include Dsfr::InputErrorable

  attr_reader :attribute

  def initialize(form:, champ:, seen_at: nil, opts: {}, aria_labelledby_prefix: nil)
    @form, @champ, @seen_at, @opts, @aria_labelledby_prefix = form, champ, seen_at, opts, aria_labelledby_prefix
    @attribute = :value
  end

  def dsfr_champ_container
    :div
  end

  def dsfr_input_classname
    nil
  end

  def describedby_id
    @champ.describedby_id
  end

  def labelledby_id
    @aria_labelledby_prefix ? "#{@aria_labelledby_prefix} #{@champ.labelledby_id}" : @champ.labelledby_id
  end

  def fieldset_aria_opts
    if dsfr_champ_container == :fieldset
      labelledby = [@champ.labelledby_id]
      labelledby << describedby_id if @champ.description.present?

      {
        aria: { labelledby: labelledby.join(' ') },
        role: 'group',
      }
    else
      {}
    end
  end
end
