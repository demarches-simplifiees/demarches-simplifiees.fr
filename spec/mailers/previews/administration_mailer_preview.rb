class AdministrationMailerPreview < ActionMailer::Preview
  def dubious_procedures
    procedures_and_champs = [
      [Procedure.first, [TypeDeChamp.new(libelle: 'iban'), TypeDeChamp.new(libelle: 'religion')]],
      [Procedure.last, [TypeDeChamp.new(libelle: 'iban'), TypeDeChamp.new(libelle: 'numéro de carte bleu')]]
    ]
    AdministrationMailer.dubious_procedures(procedures_and_champs)
  end
end
