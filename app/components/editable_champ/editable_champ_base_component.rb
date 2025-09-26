# frozen_string_literal: true

class EditableChamp::EditableChampBaseComponent < ApplicationComponent
  include Dsfr::InputErrorable

  attr_reader :attribute
  attr_reader :aria_labelledby_prefix

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

  def labelledby_id(label_id = nil)
    labelledby = []
    # in repetition, aria_labelledby_prefix is the fieldset legend id
    labelledby << @aria_labelledby_prefix if @aria_labelledby_prefix.present?
    # in a type de champ with a fieldset (ex: address), we add the fieldset legend id of the type de champ
    labelledby << fieldset_legend_id if dsfr_champ_container == :fieldset
    # we add the label id of the input
    labelledby << (label_id.presence || @champ.labelledby_id)

    labelledby.join(' ')
  end

  def fieldset_legend_id
    @champ.labelledby_id
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
