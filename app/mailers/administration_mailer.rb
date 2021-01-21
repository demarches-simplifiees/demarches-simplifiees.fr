# Preview all emails at http://localhost:3000/rails/mailers/administration_mailer
class AdministrationMailer < ApplicationMailer
  layout 'mailers/layout'

  def new_admin_email(admin, administration)
    @admin = admin
    @administration = administration
    subject = "Création d'un compte admininistrateur"

    mail(to: TECH_EMAIL, subject: subject)
  end

  def invite_admin(user, reset_password_token, administration_id)
    @reset_password_token = reset_password_token
    @user = user
    @author_name = BizDev.full_name(administration_id)
    subject = "Activez votre compte administrateur"

    mail(to: user.email, subject: subject, reply_to: CONTACT_EMAIL)
  end

  def refuse_admin(admin_email)
    subject = "Votre demande de compte a été refusée"

    mail(to: admin_email, subject: subject, reply_to: CONTACT_EMAIL)
  end

  def dubious_procedures(procedures_and_type_de_champs)
    @procedures_and_type_de_champs = procedures_and_type_de_champs
    subject = "[RGPD] De nouvelles démarches comportent des champs interdits"

    mail(to: EQUIPE_EMAIL, subject: subject)
  end

  def procedure_published(procedure)
    @procedure = procedure
    @champs = procedure.types_de_champ
    subject = "Une nouvelle démarche vient d'être publiée"
    mail(to: EQUIPE_EMAIL, subject: subject)
  end

  def s3_synchronization_report
    uploaded_stats = S3Synchronization.uploaded_stats
    @uploaded_stats = to_array(uploaded_stats)
    checked_stats = S3Synchronization.checked_stats
    @checked_stats = to_array(checked_stats)
    @total = {
      blobs_count: ActiveStorage::Blob.count,
      uploaded_count: uploaded_stats.reduce(0) { |sum, line| sum + line.count },
      checked_count: checked_stats.reduce(0) { |sum, line| sum + line.count },
      uploaded_size: size_to_string(uploaded_stats.reduce(0) { |sum, line| sum + line.size })
    }
    mail(to: EQUIPE_EMAIL, subject: "Statistiques de synchronisation")
  end

  private

  def to_array(tuples)
    tuples.map { |l| [l.date.strftime('%d %B'), l.count, size_to_string(l.size)] }
  end

  def size_to_string(size)
    if size > 1024 * 1024
      "#{(size / 1024.0 / 1024).round(2)}Mo"
    elsif size > 1024
      "#{(size / 1024.0).round(2)}ko"
    else
      "#{size.to_int}o"
    end
  end
end
