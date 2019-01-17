describe 'new_user/procedure_footer.html.haml', type: :view do
  let(:service) { create(:service) }
  let(:dossier) {
    dossier = create(:dossier)
    dossier.procedure.service = service
    return dossier
  }

  subject { render 'new_user/procedure_footer.html.haml', procedure: dossier.procedure, dossier: dossier }

  it "affiche les informations de contact" do
    expect(subject).to have_text(service.nom)
    expect(subject).to have_text(service.organisme)
    expect(subject).to have_text(service.telephone)
  end

  it "affiche les liens usuels requis" do
    expect(subject).to have_link("Accessibilité")
    expect(subject).to have_link("CGU")
    expect(subject).to have_link("Mentions légales")
  end

  context "quand le dossier n'a pas de service associé" do
    let(:service) { nil }

    it { is_expected.to have_selector("footer") }
    it { is_expected.to have_link("Accessibilité") }
    it { is_expected.not_to have_text('téléphone') }
  end
end
