namespace :'2018_05_14_add_annotation_privee_to_procedure' do
  task add: :environment do
    procedure_id = ENV['PROCEDURE_ID'] || 3723
    add_an_annotation_privee(procedure_id)
    update_description(procedure_id)
  end

  def add_an_annotation_privee(procedure_id)
    new_tdc_order_place = 7

    TypeDeChamp
      .where(procedure_id: procedure_id, private: true)
      .where('order_place >= ?', new_tdc_order_place)
      .each do |tdc|
        tdc.update_attribute(:order_place, tdc.order_place + 1)
      end

    new_tdc = TypeDeChamp.create(
      procedure_id: procedure_id,
      private: true,
      libelle: 'URL Espace de consultation',
      order_place: new_tdc_order_place,
      type_champ: 'text',
      description: 'L’instructeur renseigne l’URL du site de dépôt des observations ou la page web de la préfecture où est mentionné l’email pour déposer les commentaires'
    )

    Dossier.includes(champs: :type_de_champ).where(procedure_id: procedure_id).all.each do |dossier|
      Champs::TextChamp.create(
        dossier: dossier,
        type_de_champ: new_tdc,
        private: true
      )
    end
  end

  def update_description(procedure_id)
    TypeDeChamp.find_by(
      private: true,
      description: "L'instructeur en préfecture saisie la date de publication de l'avis à consultation du public  ",
      procedure_id: procedure_id
    )&.update(
      description: "L'instructeur en préfecture saisie la première date de publication de l'avis à consultation du public"
    )

    TypeDeChamp.find_by(
      private: false,
      libelle: "Fichier(s) Etude d'impact",
      procedure_id: procedure_id
    )&.update(
      libelle: "Fichier Etude d'impact",
      description: "Vous devez télé-charger votre fichier constituant le document dit \"étude d'impact\" de votre projet.\r\nObligatoire."
    )
  end
end
