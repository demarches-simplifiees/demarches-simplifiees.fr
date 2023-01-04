describe Temporary::BatchUpdatePaysValuesJob, type: :job do
  let!(:correct_champ) { build(:champ_pays, value: 'France', external_id: 'FR') }
  let!(:incorrect_champ) { build(:champ_pays, value: 'Incorrect') }
  let!(:easily_cleanable_champ) { build(:champ_pays, value: 'Vietnam') }
  let!(:hard_to_clean_champ) { build(:champ_pays, value: 'CHRISTMAS (ILE)') }

  before do
    correct_champ.save(validate: false)
    incorrect_champ.save(validate: false)
    easily_cleanable_champ.save(validate: false)
    hard_to_clean_champ.save(validate: false)
  end

  subject { described_class.perform_now([correct_champ.id, incorrect_champ.id, easily_cleanable_champ.id, hard_to_clean_champ.id]) }

  it 'does not touch correct_champ' do
    subject
    expect(correct_champ.reload.value).to eq('France')
    expect(correct_champ.reload.external_id).to eq('FR')
  end

  it 'updates incorrect_champ to nil' do
    subject
    expect(incorrect_champ.reload.value).to be_nil
    expect(incorrect_champ.reload.external_id).to be_nil
  end

  it 'cleans easily cleanable' do
    subject
    expect(easily_cleanable_champ.reload.value).to eq('Vietnam')
    expect(easily_cleanable_champ.reload.external_id).to eq('VN')
  end

  it 'cleans hard to clean' do
    subject
    expect(hard_to_clean_champ.reload.value).to eq('Christmas, Île')
    expect(hard_to_clean_champ.reload.external_id).to be_nil
  end
end
