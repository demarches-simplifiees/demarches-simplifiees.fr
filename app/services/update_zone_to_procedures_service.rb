class UpdateZoneToProceduresService
  def self.call(lines)
    errors = []
    lines.each do |line|
      zone_label = line["POL_PUB_MINISTERE RATTACHEMENT"]
      zone = Zone.find_by(acronym: zone_label)
      if zone.nil?
        errors << "Zone #{zone_label} introuvable"
      else
        id = line["id"]
        procedure = Procedure.find_by(id: id)
        if procedure
          procedure.update(zone: zone)
        else
          errors << "Procedure #{id} introuvable"
        end
      end
    end
    errors
  end
end
