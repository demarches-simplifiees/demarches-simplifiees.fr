describe '20190622010051_normalize_nom_and_prenom' do
  let(:dossiers) {
    [
      create(:dossier, individual: create(:individual, nom: 'lefèvre', prenom: 'ADÉLAIDE')),
      create(:dossier, individual: create(:individual, nom: 'de la tourandière', prenom: 'ANNE GAELLE')),
      create(:dossier, individual: create(:individual, nom: 'Lalumière-Dufour', prenom: 'ANNE-GAELLE')),
      create(:dossier, individual: create(:individual, nom: "D'Ornano", prenom: 'franÇois-jean')),
      create(:dossier, individual: create(:individual, nom: "de la fayette", prenom: 'gilbert'))
    ]
  }
  let(:rake_task) { Rake::Task['after_party:normalize_nom_and_prenom'] }

  before do
    dossiers
    rake_task.invoke
  end

  after { rake_task.reenable }

  it 'normalize noms et prenom' do
    expect(dossiers.map { |dossier| dossier.individual.reload.nom }).to eq(['LEFÈVRE', 'DE LA TOURANDIÈRE', 'LALUMIÈRE-DUFOUR', "D'ORNANO", "DE LA FAYETTE"])
    expect(dossiers.map { |dossier| dossier.individual.reload.prenom }).to eq(['Adélaide', 'Anne Gaelle', 'Anne-Gaelle', "François-Jean", "Gilbert"])
  end
end
