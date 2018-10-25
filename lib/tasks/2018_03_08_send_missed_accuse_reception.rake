namespace :'2018_03_08_send_missing_accuse_reception' do
  task send: :environment do
    # Send accusés de réception that were missed because of #1510
    #
    # The bug was introduced in production with the 2018-03-01-01 release
    # and fixed with the 2018-03-05-03 release.
    #
    # `bug_date` and `fix_date` were determined empirically by looking at the release times,
    # and checking for dossiers with a missing accusé de réception.

    bug_date = Time.zone.local(2018, 3, 1, 9, 50)
    fix_date = Time.zone.local(2018, 3, 5, 18, 40)

    # Only send the accusé for dossiers that are still en construction.
    # For dossiers that have moved on, other mails have been sent since, and a late
    # accusé de réception would add more confusion than it’s worth
    problem_dossiers = Dossier.where(en_construction_at: bug_date..fix_date)
    total = problem_dossiers.count
    problem_dossiers.find_each(batch_size: 100).with_index do |dossier, i|
      print "Dossier #{i}/#{total}\n"
      template = dossier.procedure.initiated_mail_template
      date_depot = dossier.en_construction_at.in_time_zone("Paris").strftime('%d/%m/%Y à %H:%M')
      body_prefix = "<p>Suite à une difficulté technique, veuillez recevoir par la présente l’accusé de réception pour votre dossier déposé le #{date_depot}.<br>L’équipe demarches-simplifiees.fr vous présente ses excuses pour la gène occasionnée.</p><hr>\n"
      template.body = body_prefix + template.body
      NotificationMailer.send_notification(dossier, template).deliver_now!
    end
  end
end
