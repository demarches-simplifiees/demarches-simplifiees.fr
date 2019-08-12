describe 'instructeurs/dossiers/envoyer_dossier_block.html.haml', type: :view do
  let(:dossier) { create(:dossier) }

  subject do
    render(
      'instructeurs/dossiers/envoyer_dossier_block.html.haml',
      dossier: dossier,
      potential_recipients: potential_recipients
    )
  end

  context "there are other instructeurs for the procedure" do
    let(:instructeur) { create(:instructeur, email: 'yop@totomail.fr') }
    let(:potential_recipients) { [instructeur] }

    it { is_expected.to have_css("select > option[value='#{instructeur.id}']") }
    it { is_expected.to have_css(".button.send") }
  end

  context "there is no other instructeur for the procedure" do
    let(:potential_recipients) { [] }

    it { is_expected.not_to have_css("select") }
    it { is_expected.not_to have_css(".button.send") }
    it { is_expected.to have_content("Vous êtes le seul instructeur assigné sur cette démarche") }
  end
end
