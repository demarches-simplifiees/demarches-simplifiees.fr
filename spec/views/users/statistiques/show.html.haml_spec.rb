describe 'users/statistiques/show.html.haml', type: :view do
  let(:procedure) { create(:procedure) }

  before do
    assign(:procedure, procedure)
  end

  subject { render }

  it "display stats" do
    expect(subject).to have_text("RÉPARTITION PAR SEMAINE")
    expect(subject).to have_text("AVANCÉE DES DOSSIERS")
    expect(subject).to have_text("TAUX D’ACCEPTATION")
    expect(subject).to have_text(procedure.libelle)
  end
end
