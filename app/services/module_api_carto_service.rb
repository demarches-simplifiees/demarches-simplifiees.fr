class ModuleApiCartoService
  def self.save_qp!(dossier, json_latlngs)
    if dossier.procedure.module_api_carto.quartiers_prioritaires?
      qp_list = generate_qp(JSON.parse(json_latlngs))

      qp_list.each do |qp|
        qp[:dossier_id] = dossier.id
        qp[:geometry] = qp[:geometry].to_json
        QuartierPrioritaire.create(qp)
      end
    end
  end

  def self.save_cadastre!(dossier, json_latlngs)
    if dossier.procedure.module_api_carto.cadastre?
      cadastre_list = generate_cadastre JSON.parse(json_latlngs)

      cadastre_list.each do |cadastre|
        cadastre[:dossier_id] = dossier.id
        cadastre[:geometry] = cadastre[:geometry].to_json
        Cadastre.create(cadastre)
      end
    end
  end

  def self.generate_qp(coordinates)
    coordinates.flat_map do |coordinate|
      ApiCarto::QuartiersPrioritaires::Adapter.new(
        coordinate.map { |element| [element['lng'], element['lat']] }
      ).results
    end
  end

  def self.generate_cadastre(coordinates)
    coordinates.flat_map do |coordinate|
      ApiCarto::Cadastre::Adapter.new(
        coordinate.map { |element| [element['lng'], element['lat']] }
      ).results
    end
  end
end
