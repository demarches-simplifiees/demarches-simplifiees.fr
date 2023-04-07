describe 'instructeurs/dossiers/show.html.haml', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:dossier) { create(:dossier, :en_construction) }

  before do
    sign_in(current_instructeur.user)
    allow(view).to receive(:current_instructeur).and_return(current_instructeur)
    assign(:dossier, dossier)
  end

  subject { render }

  it 'renders the header' do
    expect(subject).to have_text("Dossier nº #{dossier.id}")
  end

  it 'renders the dossier infos' do
    expect(subject).to have_text('Identité')
    expect(subject).to have_text('Demande')
  end

  it 'renders the correct dossier state' do
    expect(subject).to have_text('en construction')
  end

  context 'with a motivation' do
    let(:dossier) { create :dossier, :accepte, :with_motivation }

    it 'displays the motivation text' do
      expect(subject).to have_content(dossier.motivation)
    end
  end

  context 'with an attestation' do
    let(:dossier) { create :dossier, :accepte, :with_attestation }

    it 'provides a link to the attestation' do
      expect(subject).to have_text('Attestation')
      expect(subject).to have_link(href: attestation_instructeur_dossier_path(dossier.procedure, dossier))
    end
  end

  context 'with a justificatif' do
    let(:dossier) do
      dossier = create(:dossier, :accepte, :with_justificatif)
      dossier.justificatif_motivation.blob.update(virus_scan_result: ActiveStorage::VirusScanner::SAFE)
      dossier
    end

    it 'allows to download the justificatif' do
      expect(subject).to have_css("a[href*='/rails/active_storage/blobs/']", text: dossier.justificatif_motivation.attachment.filename.to_s)
    end
  end

  context 'en_contruction' do
    let(:dossier) { create(:dossier, :en_construction) }
    it 'displays the correct actions' do
      within("form[action=\"#{passer_en_instruction_instructeur_dossier_path(dossier.procedure, dossier)}\"]") do
        expect(subject).to have_button('Passer en instruction')
      end
      within("form[action=\"#{follow_instructeur_dossier_path(dossier.procedure, dossier)}\"]") do
        expect(subject).to have_button('Suivre le dossier')
      end
      expect(subject).to have_selector('.header-actions ul:first-child .fr-btn', count: 2)
    end
  end

  context 'en_instruction' do
    let(:dossier) { create(:dossier, :en_instruction) }

    before do
      current_instructeur.followed_dossiers << dossier
      render
    end

    it 'displays the correct actions' do
      within("form[action=\"#{repasser_en_construction_instructeur_dossier_path(dossier.procedure, dossier)}\"]") do
        expect(subject).to have_button('Repasser en construction')
      end
      within("form[action=\"#{unfollow_instructeur_dossier_path(dossier.procedure, dossier)}\"]") do
        expect(subject).to have_button('Ne plus suivre')
      end
      expect(subject).to have_button('Instruire le dossier')
      expect(subject).to have_selector('.header-actions ul:first-child > li .fr-btn', count: 15)
      expect(subject).to have_selector('.header-actions ul:first-child > li.instruction-button', count: 1)
    end
  end

  context 'accepte' do
    let(:dossier) { create(:dossier, :accepte) }

    it 'displays the correct actions' do
      within("form[action=\"#{repasser_en_instruction_instructeur_dossier_path(dossier.procedure, dossier)}\"]") do
        expect(subject).to have_button('Repasser en instruction')
      end
      within("form[action=\"#{archive_instructeur_dossier_path(dossier.procedure, dossier)}\"]") do
        expect(subject).to have_button('Archiver le dossier')
      end
      expect(subject).to have_selector('[title^="Supprimer le dossier"]')
      expect(subject).to have_selector('.header-actions ul:first-child .fr-btn', count: 3)
    end
  end

  context 'supprime' do
    let(:dossier) { create(:dossier, :accepte) }

    before do
      dossier.hide_and_keep_track!(current_instructeur, :instructeur_request)
      render
    end

    it 'displays the correct actions' do
      within("form[action=\"#{restore_instructeur_dossier_path(dossier.procedure, dossier)}\"]") do
        expect(subject).to have_button('Restaurer')
      end
      expect(subject).to have_selector('.header-actions ul:first-child .fr-btn', count: 1)
    end
  end

  context 'expirant' do
    let(:procedure) { create(:procedure, :published, duree_conservation_dossiers_dans_ds: 6, procedure_expires_when_termine_enabled: true) }
    let!(:dossier) { create(:dossier, state: :accepte, procedure: procedure, processed_at: 175.days.ago) }

    it 'displays the correct actions' do
      expect(subject).to have_text('Conserver un mois de plus')
      within("form[action=\"#{repasser_en_instruction_instructeur_dossier_path(dossier.procedure, dossier)}\"]") do
        expect(subject).to have_button('Repasser en instruction')
      end
      expect(subject).to have_selector('.header-actions ul:first-child .fr-btn', count: 2)
    end
  end

  context 'archived' do
    let(:dossier) { create(:dossier, :accepte, :archived) }

    it 'displays the correct actions' do
      within("form[action=\"#{unarchive_instructeur_dossier_path(dossier.procedure, dossier)}\"]") do
        expect(subject).to have_button('Désarchiver le dossier')
      end
      expect(subject).to have_selector('[title^="Supprimer le dossier"]')
      expect(subject).to have_selector('.header-actions ul:first-child .fr-btn', count: 2)
    end
  end

  context 'when the user is logged in with france connect' do
    let(:france_connect_information) { build(:france_connect_information) }
    let(:user) { build(:user, france_connect_information: france_connect_information) }
    let(:procedure1) { create(:procedure, :with_type_de_champ, for_individual: true) }
    let(:dossier) { create(:dossier, procedure: procedure1, user: user) }

    before do
      render
    end

    it 'fills the individual with the informations from France Connect' do
      expect(view.content_for(:notice_info)).to have_text("Le dossier a été déposé par le compte de #{france_connect_information.given_name} #{france_connect_information.family_name}, authentifié par FranceConnect le #{france_connect_information.updated_at.strftime('%d/%m/%Y')}")
    end
  end

  describe 'entreprise degraded mode' do
    context 'etablissement complete' do
      let(:dossier) { create(:dossier, :en_construction, :with_entreprise, as_degraded_mode: false) }

      it 'contains no warning' do
        expect(subject).not_to have_text("Les services de l’INSEE sont indisponibles")
      end
    end

    context 'etablissement in degraded mode' do
      let(:dossier) { create(:dossier, :en_construction, :with_entreprise, as_degraded_mode: true) }

      it 'warns the instructeur' do
        expect(subject).to have_text("Les services de l’INSEE sont indisponibles")
      end
    end
  end
end
