class APITeFenua::PlaceAdapter < APITeFenua::Adapter
  def initialize(place)
    super(place, [])
  end

  def suggestions
    handle_result
  end

  private

  def process(features)
    features.map do |f|
      source = f[:_source]
      if source.present?
        result = {
          label: "#{source[:resultat_titre]} - #{source[:resultat_localisation]}",
          point: source[:point][:coordinates]
        }
        e = source[:extent]
        if e.present? && e.length == 4 && e[0] != e[2] && e[1] != e[3]
          result[:extent] = e
        end
        result
      else
        nil
      end
    end
  end
end
