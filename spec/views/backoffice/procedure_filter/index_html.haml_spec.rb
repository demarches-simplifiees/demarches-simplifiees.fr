require 'spec_helper'

describe 'backoffice/procedure_filter/index.html.haml', type: :view do
  let(:administrateur) { create :administrateur }

  before do
    create :procedure, libelle: 'plip', administrateur: administrateur
    create :procedure, libelle: 'plop', administrateur: administrateur
    create :procedure, libelle: 'plap', administrateur: administrateur
  end

  context 'when gestionnaire have already check procedure' do
    let(:gestionnaire) { create(:gestionnaire,
                                administrateur: administrateur,
                                procedure_filter: [administrateur.procedures.first.id,
                                                   administrateur.procedures.last.id]) }

    before do
      sign_in gestionnaire

      assign(:gestionnaire, gestionnaire)
      assign(:procedures, gestionnaire.procedures)

      render
    end

    subject { rendered }

    it { is_expected.to have_content('Filtre des procédures') }
    it { is_expected.to have_css("input[type=checkbox][value='#{gestionnaire.procedures.first.id}'][checked=checked]") }
    it { is_expected.to have_css("input[type=checkbox][value='#{gestionnaire.procedures.last.id}'][checked=checked]") }
  end
end