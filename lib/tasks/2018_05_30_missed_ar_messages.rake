namespace :'2018_05_30_missed_ar_messages' do
  task restore: :environment do
    create_commentaires(:en_construction_at, :initiated_mail_template)
    create_commentaires(:processed_at, :closed_mail_template, Dossier.where(state: 'accepte'))
    create_commentaires(:processed_at, :refused_mail_template, Dossier.where(state: 'refuse'))
    create_commentaires(:processed_at, :without_continuation_mail_template, Dossier.where(state: 'sans_suite'))
  end

  def create_commentaires(date_name, template_name, dossiers = Dossier)
    error_range = Time.zone.local(2018, 05, 28, 13, 33)..Time.zone.local(2018, 05, 30, 15, 39)

    dossiers.includes(:procedure).where(date_name => error_range).find_each(batch_size: 100) do |dossier|
      print "#{dossier.id}\n"
      create_commentaire(dossier, dossier.procedure.send(template_name), dossier.send(date_name))
    end
  end

  def create_commentaire(dossier, template, date)
    subject = template.subject_for_dossier(dossier)
    body = template.body_for_dossier(dossier)

    Commentaire.create(
      dossier: dossier,
      email: CONTACT_EMAIL,
      body: "[#{subject}]<br><br>#{body}",
      created_at: date
    )
  end
end
