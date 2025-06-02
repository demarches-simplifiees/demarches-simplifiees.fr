# frozen_string_literal: true

class Champs::AutoCompletionChamp < Champ
  def options?
    drop_down_list_options?
  end

  def options
    drop_down_list_options | [value]
  end

  def disabled_options
    drop_down_list_disabled_options
  end
end
