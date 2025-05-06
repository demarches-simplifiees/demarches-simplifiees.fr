# frozen_string_literal: true

class EditableChamp::EditableChampBaseComponent < ApplicationComponent
  include Dsfr::InputErrorable

  attr_reader :attribute

  def initialize(form:, champ:, seen_at: nil, opts: {}, input_labelled_by_prefix: nil)
    @form, @champ, @seen_at, @opts, @input_labelled_by_prefix = form, champ, seen_at, opts, input_labelled_by_prefix
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
    @input_labelled_by_prefix ? "#{@input_labelled_by_prefix} #{@champ.labelledby_id}" : @champ.labelledby_id
  end

  def fieldset_aria_opts
    if dsfr_champ_container == :fieldset
      labelledby = [@champ.labelledby_id]
      labelledby << describedby_id if @champ.description.present?

      {
        aria: { labelledby: labelledby.join(' ') },
        role: 'group'
      }
    else
      {}
    end
  end
end
