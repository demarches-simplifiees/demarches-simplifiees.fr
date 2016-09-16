class MailTemplate < ActiveRecord::Base
  belongs_to :procedure

  enum tags: {
           numero_dossier: {
               description: "Permet d'afficher le numéro de dossier de l'utilisateur."
           },
           libelle_procedure: {
               description: "Permet d'afficher le libellé de la procédure."
           }
       }

  def self.replace_tags string, dossier
    @dossier = dossier

    tags.inject(string) do |acc, tag|
      acc.gsub!("--#{tag.first}--", replace_tag(tag.first.to_sym)) || acc
    end
  end

  private

  def self.replace_tag tag
    case tag
      when :numero_dossier
        @dossier.id.to_s
      when :libelle_procedure
        @dossier.procedure.libelle
      else
        '--BALISE_NON_RECONNUE--'
    end
  end
end
