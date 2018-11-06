class Champs::DecimalNumberChampSerializer < ChampSerializer
  def value
    if object.value.present?
      object.value.to_f
    end
  end
end
