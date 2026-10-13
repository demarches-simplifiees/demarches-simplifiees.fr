# frozen_string_literal: true

describe 'users/dossiers/etablissement', type: :view do
  let(:etablissement) { create(:etablissement, :with_exercices, siret: "12345678900001") }
  let(:dossier) { create(:dossier, etablissement: etablissement) }
  let(:footer) { view.content_for(:footer) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
    allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return([])
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject! { render }

  it 'affiche les informations de l’établissement' do
    expect(rendered).to have_text("123 456 789 00001")
    expect(rendered).to have_text(etablissement.entreprise_raison_sociale)
  end

  context 'etablissement avec infos non diffusables' do
    let(:etablissement) { create(:etablissement, :with_exercices, :non_diffusable, siret: "12345678900001") }
    it "affiche uniquement le SIRET si infos non diffusables" do
      expect(rendered).to have_text("123 456 789 00001")
      expect(rendered).not_to have_text(etablissement.entreprise_raison_sociale)
      expect(rendered).not_to have_text(etablissement.entreprise.forme_juridique)
    end
  end

  it 'prépare le footer' do
    expect(footer).to have_selector('footer')
  end

  context 'with an unverified SIRET and no etablissement' do
    let(:dossier) { create(:dossier, procedure: procedures.entreprise) }

    subject! do
      dossier.procedure.update!(api_entreprise_token: JWT.encode({ exp: 2.months.from_now.to_i }, nil, 'none'))
      dossier.create_demandeur_siret!(siret: '30613890001294', external_state: 'degraded')
      render
    end

    it 'explains the SIRET could not be checked and lets the usager go on' do
      expect(rendered).to have_text('Nous n’avons pas pu vérifier votre SIRET')
      expect(rendered).to have_text('306 138 900 01294')
      expect(rendered).to have_text('L’annuaire INSEE est indisponible')
      expect(rendered).to have_link('Vérifier dans l’annuaire des entreprises', href: 'https://annuaire-entreprises.data.gouv.fr/rechercher?terme=30613890001294')
      expect(rendered).to have_link('Continuer avec ces informations')
    end

    context 'when the token of the procedure is rejected' do
      subject! do
        dossier.create_demandeur_siret!(siret: '30613890001294', external_state: 'degraded')
        dossier.procedure.update!(api_entreprise_token_rejected_at: Time.current)
        render
      end

      it 'does not blame the INSEE' do
        expect(rendered).not_to have_text('L’annuaire INSEE est indisponible')
        expect(rendered).to have_text('Les informations sur l’entreprise n’ont pas pu être récupérées')
      end
    end
  end
end
