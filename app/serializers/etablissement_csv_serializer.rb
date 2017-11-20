class EtablissementCsvSerializer < EtablissementSerializer
  def adresse
    object.adresse.chomp.gsub("\r\n", ' ').delete("\r")
  end
end
