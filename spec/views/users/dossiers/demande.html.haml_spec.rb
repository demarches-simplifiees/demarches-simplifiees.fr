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
    expect(rendered).to have_text("Dossier numéro nº #{dossier.id}")
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
    let(:user) { build(:user, france_connect_informations: [france_connect_information]) }
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

  context 'when there is a dropdown list from a referentiel' do
    let!(:procedure) { create(:procedure, types_de_champ_public: [{ type: :drop_down_list }]) }
    let(:type_de_champ) { procedure.draft_types_de_champ_public.first }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:champ) { dossier.champs.first }

    before do
      referentiel = type_de_champ.create_referentiel!(name: 'referentiel.csv')

      csv_to_code = [{ 'option' => 'fromage', 'calorie (kcal)' => '145', 'poids (g)' => '60' }, { 'option' => 'dessert', 'calorie (kcal)' => '170', 'poids (g)' => '70' }, { 'option' => 'fruit', 'calorie (kcal)' => '100', 'poids (g)' => '50' }]
      keys = csv_to_code.first.keys
      csv_to_code.each do |row|
        referentiel.items.create!(option: row.slice(keys.first), data: row.except(keys.first))
      end

      type_de_champ.update!(drop_down_mode: 'referentiel')
      dossier.champs.first.update!(value: referentiel.items.first.id)
      dossier.reload
      render
    end

    it 'display only the first option to the user' do
      expect(rendered).to have_text('fromage')
      expect(rendered).not_to have_text('dessert')
    end
  end
end
