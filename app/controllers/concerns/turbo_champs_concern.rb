module TurboChampsConcern
  extend ActiveSupport::Concern

  private

  def champs_to_turbo_update(params, champs)
    champ_ids = params.keys.map(&:to_i)

    to_update = champs.filter { _1.id.in?(champ_ids) && _1.refresh_after_update? }
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
