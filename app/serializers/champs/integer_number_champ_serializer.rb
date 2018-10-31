class Champs::IntegerNumberChampSerializer < ChampSerializer
  def value
    if object.value.present?
      object.value.to_i
    end
  end
end
