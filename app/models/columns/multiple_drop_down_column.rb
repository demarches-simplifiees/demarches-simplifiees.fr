# frozen_string_literal: true

class Columns::MultipleDropDownColumn < Columns::JSONPathColumn
  private

  def typed_value(champ)
    JsonPath.on(champ.value_json, jsonpath).join(', ')
  end
end
