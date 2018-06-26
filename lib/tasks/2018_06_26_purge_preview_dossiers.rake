require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2018_06_26_purge_preview_dossiers' do
  task run: :environment do
    # We use delete_all and manually destroy associations because it’s so much faster that Champ.where(dossier_id: 0).destroy_all

    c_count = Commentaire.joins(:champ).where(champs: { dossier_id: 0 }).delete_all
    rake_puts("Deleted #{c_count} commentaires\n")
    a_count = ActiveStorage::Attachment.joins('join champs ON active_storage_attachments.record_id = champs.id').where(champs: { dossier_id: 0 }).delete_all
    rake_puts("Deleted #{a_count} attachments\n")
    v_count = VirusScan.joins(:champ).where(champs: { dossier_id: 0 }).delete_all
    rake_puts("Deleted #{v_count} virus scans\n")
    ch_count = Champ.where(dossier_id: 0).delete_all
    rake_puts("Deleted #{ch_count} champs\n")
  end
end
