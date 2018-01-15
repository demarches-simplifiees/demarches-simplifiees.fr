namespace :'2017_12_21_replace_deprecated_mail_template_tags' do
  task set: :environment do
    replace_tag('numero_dossier', 'numéro du dossier')
    replace_tag('date_de_decision', 'date de décision')
    replace_tag('libelle_procedure', 'libellé procédure')
    replace_tag('lien_dossier', 'lien dossier')
  end

  def replace_tag(old_tag, new_tag)
    mails = [Mails::ClosedMail, Mails::InitiatedMail, Mails::ReceivedMail, Mails::RefusedMail, Mails::WithoutContinuationMail]
    mails.each do |mail|
      replace_tag_in(mail, 'object', old_tag, new_tag)
      replace_tag_in(mail, 'body', old_tag, new_tag)
    end
  end

  def replace_tag_in(mail, field, old_tag, new_tag)
    mail
      .where("#{field} LIKE ?", "%#{old_tag}%")
      .update_all("#{field} = REPLACE(#{field}, '#{old_tag}', '#{new_tag}')")
  end
end
