describe '20230130094747_normalize_regions', vcr: { cassette_name: 'api_geo_regions' } do
  let(:champ) { create(:champ_regions) }
  let(:rake_task) { Rake::Task['after_party:normalize_regions'] }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  subject(:run_task) { rake_task.invoke }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  after { rake_task.reenable }

  shared_examples "a non-changer" do |external_id, value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.not_to change { champ.reload.external_id } }

    it { expect { run_task }.not_to change { champ.reload.value } }
  end

  shared_examples "an external_id nullifier" do |external_id, value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.to change { champ.reload.external_id }.from(external_id).to(nil) }

    it { expect { run_task }.not_to change { champ.reload.value } }
  end

  shared_examples "a value nullifier" do |external_id, value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.not_to change { champ.reload.external_id } }

    it { expect { run_task }.to change { champ.reload.value }.from(value).to(nil) }
  end

  shared_examples "an external_id and value nullifier" do |external_id, value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.to change { champ.reload.external_id }.from(external_id).to(nil) }

    it { expect { run_task }.to change { champ.reload.value }.from(value).to(nil) }
  end

  shared_examples "an external_id updater" do |external_id, value, expected_external_id|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.to change { champ.reload.external_id }.from(external_id).to(expected_external_id) }

    it { expect { run_task }.not_to change { champ.reload.value } }
  end

  shared_examples "a result checker" do |external_id, value, expected_external_id, expected_value|
    before do
      champ.update_columns(external_id:, value:)
      run_task
    end

    it { expect(champ.reload.external_id).to eq(expected_external_id) }

    it { expect(champ.reload.value).to eq(expected_value) }
  end

  shared_examples "a value updater" do |external_id, value, expected_value|
    before { champ.update_columns(external_id:, value:) }

    it { expect { run_task }.not_to change { champ.reload.external_id } }

    it { expect { run_task }.to change { champ.reload.value }.from(value).to(expected_value) }
  end

  it_behaves_like "a non-changer", nil, nil
  it_behaves_like "an external_id nullifier", '', nil
  it_behaves_like "a value nullifier", nil, ''
  it_behaves_like "an external_id and value nullifier", '', ''
  it_behaves_like "an external_id updater", nil, 'Auvergne-Rhône-Alpes', '84'
  it_behaves_like "an external_id updater", '', 'Auvergne-Rhône-Alpes', '84'
  it_behaves_like "a value updater", '11', nil, 'Île-de-France'

  # Integrity data check:
  it_behaves_like "a result checker", "84", "Auvergne-Rhône-Alpes", "84", "Auvergne-Rhône-Alpes"
  it_behaves_like "a result checker", nil, "Auvergne-Rhône-Alpes", "84", "Auvergne-Rhône-Alpes"
  it_behaves_like "a result checker", '', "Auvergne-Rhône-Alpes", "84", "Auvergne-Rhône-Alpes"
  it_behaves_like "a result checker", "27", "Bourgogne-Franche-Comté", "27", "Bourgogne-Franche-Comté"
  it_behaves_like "a result checker", nil, "Bourgogne-Franche-Comté", "27", "Bourgogne-Franche-Comté"
  it_behaves_like "a result checker", '', "Bourgogne-Franche-Comté", "27", "Bourgogne-Franche-Comté"
  it_behaves_like "a result checker", "53", "Bretagne", "53", "Bretagne"
  it_behaves_like "a result checker", nil, "Bretagne", "53", "Bretagne"
  it_behaves_like "a result checker", '', "Bretagne", "53", "Bretagne"
  it_behaves_like "a result checker", "24", "Centre-Val de Loire", "24", "Centre-Val de Loire"
  it_behaves_like "a result checker", nil, "Centre-Val de Loire", "24", "Centre-Val de Loire"
  it_behaves_like "a result checker", '', "Centre-Val de Loire", "24", "Centre-Val de Loire"
  it_behaves_like "a result checker", "94", "Corse", "94", "Corse"
  it_behaves_like "a result checker", nil, "Corse", "94", "Corse"
  it_behaves_like "a result checker", '', "Corse", "94", "Corse"
  it_behaves_like "a result checker", "44", "Grand Est", "44", "Grand Est"
  it_behaves_like "a result checker", nil, "Grand Est", "44", "Grand Est"
  it_behaves_like "a result checker", '', "Grand Est", "44", "Grand Est"
  it_behaves_like "a result checker", "01", "Guadeloupe", "01", "Guadeloupe"
  it_behaves_like "a result checker", nil, "Guadeloupe", "01", "Guadeloupe"
  it_behaves_like "a result checker", '', "Guadeloupe", "01", "Guadeloupe"
  it_behaves_like "a result checker", "03", "Guyane", "03", "Guyane"
  it_behaves_like "a result checker", nil, "Guyane", "03", "Guyane"
  it_behaves_like "a result checker", '', "Guyane", "03", "Guyane"
  it_behaves_like "a result checker", "32", "Hauts-de-France", "32", "Hauts-de-France"
  it_behaves_like "a result checker", nil, "Hauts-de-France", "32", "Hauts-de-France"
  it_behaves_like "a result checker", '', "Hauts-de-France", "32", "Hauts-de-France"
  it_behaves_like "a result checker", "04", "La Réunion", "04", "La Réunion"
  it_behaves_like "a result checker", nil, "La Réunion", "04", "La Réunion"
  it_behaves_like "a result checker", '', "La Réunion", "04", "La Réunion"
  it_behaves_like "a result checker", "02", "Martinique", "02", "Martinique"
  it_behaves_like "a result checker", nil, "Martinique", "02", "Martinique"
  it_behaves_like "a result checker", '', "Martinique", "02", "Martinique"
  it_behaves_like "a result checker", "06", "Mayotte", "06", "Mayotte"
  it_behaves_like "a result checker", nil, "Mayotte", "06", "Mayotte"
  it_behaves_like "a result checker", '', "Mayotte", "06", "Mayotte"
  it_behaves_like "a result checker", "28", "Normandie", "28", "Normandie"
  it_behaves_like "a result checker", nil, "Normandie", "28", "Normandie"
  it_behaves_like "a result checker", '', "Normandie", "28", "Normandie"
  it_behaves_like "a result checker", "75", "Nouvelle-Aquitaine", "75", "Nouvelle-Aquitaine"
  it_behaves_like "a result checker", nil, "Nouvelle-Aquitaine", "75", "Nouvelle-Aquitaine"
  it_behaves_like "a result checker", '', "Nouvelle-Aquitaine", "75", "Nouvelle-Aquitaine"
  it_behaves_like "a result checker", "76", "Occitanie", "76", "Occitanie"
  it_behaves_like "a result checker", nil, "Occitanie", "76", "Occitanie"
  it_behaves_like "a result checker", '', "Occitanie", "76", "Occitanie"
  it_behaves_like "a result checker", "52", "Pays de la Loire", "52", "Pays de la Loire"
  it_behaves_like "a result checker", nil, "Pays de la Loire", "52", "Pays de la Loire"
  it_behaves_like "a result checker", '', "Pays de la Loire", "52", "Pays de la Loire"
  it_behaves_like "a result checker", "93", "Provence-Alpes-Côte d'Azur", "93", "Provence-Alpes-Côte d’Azur"
  it_behaves_like "a result checker", nil, "Provence-Alpes-Côte d'Azur", "93", "Provence-Alpes-Côte d’Azur"
  it_behaves_like "a result checker", '', "Provence-Alpes-Côte d'Azur", "93", "Provence-Alpes-Côte d’Azur"
  it_behaves_like "a result checker", "93", "Provence-Alpes-Côte d’Azur", "93", "Provence-Alpes-Côte d’Azur"
  it_behaves_like "a result checker", "11", "Île-de-France", "11", "Île-de-France"
  it_behaves_like "a result checker", "11", nil, "11", "Île-de-France"
  it_behaves_like "a result checker", nil, "Île-de-France", "11", "Île-de-France"
  it_behaves_like "a result checker", '', "Île-de-France", "11", "Île-de-France"
end
