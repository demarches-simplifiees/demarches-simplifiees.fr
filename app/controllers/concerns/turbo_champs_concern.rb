# frozen_string_literal: true

module TurboChampsConcern
  extend ActiveSupport::Concern

  private

  def champs_to_turbo_update(params, champs)
    to_update = champs.filter { _1.public_id.in?(params.keys) }
      .filter { _1.refresh_after_update? || _1.forked_with_changes? }

    to_show, to_hide = champs.filter(&:conditional?)
      .partition(&:visible?)
      .map { champs_to_one_selector(_1 - to_update) }

    return to_show, to_hide, to_update
  end

  def champs_to_one_selector(champs)
    champs
      .map { "##{_1.input_group_id}" }
      .join(',')
  end
end
