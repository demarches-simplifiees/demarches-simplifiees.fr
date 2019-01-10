describe ProcedureSerializer do
  describe '#attributes' do
    subject { ProcedureSerializer.new(procedure).serializable_hash }
    let(:procedure) { create(:procedure, :published) }

    it {
      is_expected.to include(link: "http://localhost:3000/commencer/#{procedure.path}")
      is_expected.to include(state: "publiee")
    }
  end

  context 'when a type PJ was cloned to a type champ PJ' do
    let(:original_procedure) do
      p = create(:procedure, :published)
      p.types_de_piece_justificative.create(
        libelle: "Vidéo de votre demande de subvention",
        description: "Pour optimiser vos chances, soignez la chorégraphie et privilégiez le chant polyphonique",
        lien_demarche: "https://www.dance-academy.gouv.fr",
        order_place: 0
      )
      p
    end

    let(:procedure) { original_procedure.clone(original_procedure.administrateur, false) }

    let(:type_pj) { original_procedure.types_de_piece_justificative.first }
    let(:migrated_type_champ) { procedure.types_de_champ.find_by(libelle: type_pj.libelle) }

    subject { ProcedureSerializer.new(procedure).serializable_hash }

    it "is exposed as a legacy type PJ" do
      is_expected.to include(
        types_de_piece_justificative: [
          {
            "id" => type_pj.id,
            "libelle" => type_pj.libelle,
            "description" => type_pj.description,
            "lien_demarche" => type_pj.lien_demarche,
            "order_place" => type_pj.order_place
          }
        ]
      )
    end
  end
end
