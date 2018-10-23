class Champs::CarteChampSerializer < ChampSerializer
  has_many :geo_areas

  def value
    if object.value.present?
      JSON.parse(object.value)
    else
      nil
    end
  end
end
