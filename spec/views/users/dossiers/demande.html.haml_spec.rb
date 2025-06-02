# frozen_string_literal: true

describe 'users/dossiers/demande', type: :view do
  let(:procedure) { create(:procedure, :published, :with_type_de_champ, :with_type_de_champ_private) }
  let(:dossier) { create(:dossier, :en_construction, :with_entreprise, procedure: procedure) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'renders the header' do
    expect(rendered).to have_text("Dossier nº #{dossier.id}")
  end

  it 'renders the dossier infos' do
    expect(rendered).to have_text('Déposé le')
    expect(rendered).to have_text('Identité')
    expect(rendered).to have_text('Demande')
  end

  context 'when the dossier is editable' do
    it { is_expected.to have_link('Modifier le dossier', href: modifier_dossier_path(dossier)) }
  end

  context 'when the dossier is read-only' do
    let(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure: procedure) }
    it { is_expected.not_to have_link('Modifier le dossier') }
  end

  context 'when the dossier has no depose_at date' do
    let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure) }

    it { expect(rendered).not_to have_text('Déposé le') }
  end

  context 'when the user is logged in with france connect' do
    let(:france_connect_information) { build(:france_connect_information) }
    let(:loged_in_with_france_connect) { User.loged_in_with_france_connects.fetch(:particulier) }
    let(:user) { build(:user, france_connect_informations: [france_connect_information], loged_in_with_france_connect: loged_in_with_france_connect) }
    let(:procedure1) { create(:procedure, :with_type_de_champ, for_individual: true) }
    let(:dossier) { create(:dossier, procedure: procedure1, user: user) }

    before do
      render
    end

    it 'does not fill the individual with the informations from France Connect' do
      expect(view.content_for(:notice_info)).not_to have_text("Le dossier a été déposé par le compte de #{france_connect_information.given_name} #{france_connect_information.family_name}, authentifié par FranceConnect le #{france_connect_information.updated_at.strftime('%d/%m/%Y')}")
    end
  end

  context 'when a dossier is for_tiers and the dossier is en_construction with email notification' do
    let(:dossier) { create(:dossier, :en_construction, :for_tiers_with_notification) }

    it 'displays the informations of the mandataire' do
      expect(rendered).to have_text('Identité du mandataire')
      expect(rendered).to have_text(dossier.mandataire_first_name.to_s)
      expect(rendered).to have_text(dossier.mandataire_last_name.to_s)
      expect(rendered).to have_text(dossier.individual.email.to_s)
    end
  end

  context 'when a dossier is accepte with motivation' do
    let(:dossier) { create(:dossier, :accepte, :with_motivation) }

    it 'displays the motivation' do
      expect(rendered).not_to have_text('Cette démarche est soumise à un accusé de lecture.')
      expect(rendered).to have_text('Motivation')
    end
  end

  context 'when a dossier is accepte with motivation and with accuse de lecture' do
    let(:dossier) { create(:dossier, :accepte, :with_motivation, procedure: create(:procedure, :accuse_lecture)) }

    it 'display information about accuse de lecture and not the motivation' do
      expect(rendered).to have_text('Cette démarche est soumise à un accusé de lecture.')
      expect(rendered).not_to have_text('Motivation')
      expect(rendered).not_to have_text('L’usager n’a pas encore pris connaissance de la décision concernant son dossier')
    end
  end
end
