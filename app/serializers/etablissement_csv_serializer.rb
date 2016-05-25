class EtablissementCsvSerializer < EtablissementSerializer
  def adresse
    object.adresse.chomp.gsub("\r\n", ' ').gsub("\r", '')
  end
end