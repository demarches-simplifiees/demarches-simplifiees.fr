# frozen_string_literal: true

module TurboChampsConcern
  extend ActiveSupport::Concern

  private

  def champs_to_turbo_update(params, champs)
    all_champs = champs.flat_map(&:flattened_self_and_children)

    to_update = all_champs.filter { _1.public_id.in?(params.keys) }
      .filter { _1.refresh_after_update? || _1.user_buffer_changes? }
    prefillable_champs = all_champs.filter { it.referentiel? && it.autocomplete? }
    to_update += prefillable_champs.map(&:prefillable_champs).flatten.uniq if prefillable_champs.any?

    to_show, to_hide = [all_champs.filter(&:visible?), all_champs.reject(&:visible?)]
      .map { champs_to_one_selector(_1 - to_update) }

    return to_show, to_hide, to_update
  end

  def champs_to_one_selector(champs)
    champs
      .map { "##{_1.input_group_id}" }
      .join(',')
  end
end
