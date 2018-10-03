describe 'new_gestionnaire/dossiers/envoyer_dossier_block.html.haml', type: :view do
  let(:dossier) { create(:dossier) }

  subject do
    render(
      'new_gestionnaire/dossiers/envoyer_dossier_block.html.haml',
      dossier: dossier,
      potential_recipients: potential_recipients
    )
  end

  context "there are other gestionnaires for the procedure" do
    let(:gestionnaire) { create(:gestionnaire, email: 'yop@totomail.fr') }
    let(:potential_recipients) { [gestionnaire] }

    it { is_expected.to have_css("select > option[value='#{gestionnaire.id}']") }
    it { is_expected.to have_css(".button.send") }
  end

  context "there is no other gestionnaire for the procedure" do
    let(:potential_recipients) { [] }

    it { is_expected.not_to have_css("select") }
    it { is_expected.not_to have_css(".button.send") }
    it { is_expected.to have_content("Vous êtes le seul instructeur assigné sur cette démarche") }
  end
end
