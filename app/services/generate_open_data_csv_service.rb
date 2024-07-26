class GenerateOpenDataCsvService
  def self.save_csv_to_tmp(file_name, data)
    f = Tempfile.create(["#{file_name}_#{date_last_month}", '.csv'], 'tmp')
    f << generate_csv(file_name, data)
    f.rewind
    yield f if block_given?
    f.close
  end

  def self.date_last_month
    Date.today.prev_month.strftime("%B")
  end

  def self.generate_csv(file_name, data)
    case file_name
    when "nb_champs_remplis_par_mois"
      headers = ["mois", "procedure_id", "type_de_champ_id", "type_champ", "libelle", "nb_champs_remplis"]
      data.map! { |d| d.unshift(date_last_month) }
    else
      headers = ["mois", file_name]
      data = [[date_last_month, data]]
    end

    SpreadsheetArchitect.to_csv(headers: headers, data: data)
  end
end
