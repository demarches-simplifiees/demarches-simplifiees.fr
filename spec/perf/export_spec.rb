# frozen_string_literal: true

describe 'Export performance' do
  let(:instructeur) { create(:instructeur) }
  let(:types_de_champ_public) do
    [
      { type: :text, libelle: 'Nom' },
      { type: :textarea, libelle: 'Description' },
      { type: :integer_number, libelle: 'Nombre' },
      { type: :date, libelle: 'Date' },
      { type: :piece_justificative, libelle: 'Justificatif' },
    ]
  end
  let(:types_de_champ_private) do
    [
      { type: :text, libelle: 'Note interne' },
    ]
  end
  let(:procedure) { create(:procedure, :published, :for_individual, types_de_champ_public:, types_de_champ_private:, instructeurs: [instructeur]) }
  let(:expert) { create(:expert) }
  let(:experts_procedure) { create(:experts_procedure, expert:, procedure:) }

  def create_dossier_with_associations(state)
    dossier = create(:dossier, state, :with_individual, :with_populated_champs, procedure:)

    create(:traitement, dossier:, state:)

    create(:commentaire, dossier:, instructeur:)
    create(:commentaire, dossier:, expert:)
    create(:commentaire, dossier:)

    create(:avis, dossier:, claimant: instructeur, experts_procedure:)

    commentaire_correction = create(:commentaire, dossier:, instructeur:)
    create(:dossier_correction, dossier:, commentaire: commentaire_correction)

    dossier
  end

  describe 'generate_dossiers_export' do
    let!(:dossiers) do
      # Mix of states to test all code paths including pending_correction?
      dossiers = []
      5.times { dossiers << create_dossier_with_associations(:en_construction) }
      5.times { dossiers << create_dossier_with_associations(:en_instruction) }
      5.times { dossiers << create_dossier_with_associations(:accepte) }
      dossiers
    end
    let(:pj_service) { PiecesJustificativesService.new(user_profile: instructeur, export_template: nil) }

    it 'does not have N+1 queries', :slow do
      all_dossiers = Dossier.where(id: dossiers.map(&:id))

      query_count = 0

      ActiveSupport::Notifications.subscribed(lambda { |*_args| query_count += 1 }, "sql.active_record") do
        DossierPreloader.new(all_dossiers).in_batches_with_block do |loaded|
          pj_service.generate_dossiers_export(loaded)
        end
      end

      expect(query_count).to be <= 35
    end
  end
end
