# frozen_string_literal: true

describe '20240912091625_clean_drop_down_options.rake' do
  let(:rake_task) { Rake::Task['after_party:clean_drop_down_options'] }

  let!(:dashed_drop_down_list) do
    drop_down_options = ['1', '-- nop --', '2']
    create(:type_de_champ_drop_down_list, drop_down_options:)
  end

  let!(:witness_drop_down_list) do
    drop_down_options = ['1', 'hi', '2']
    create(:type_de_champ_drop_down_list, drop_down_options:)
  end

  let!(:multiple_drop_down_list) do
    drop_down_options = ['1', '-- nop --', '2']
    create(:type_de_champ_multiple_drop_down_list, drop_down_options:)
  end

  before do
    rake_task.invoke

    [dashed_drop_down_list, witness_drop_down_list, multiple_drop_down_list].each(&:reload)
  end

  after { rake_task.reenable }

  it 'removes the hidden options' do
    expect(dashed_drop_down_list.drop_down_options).to eq(['1', '2'])
    expect(witness_drop_down_list.drop_down_options).to eq(['1', 'hi', '2'])
    expect(multiple_drop_down_list.drop_down_options).to eq(['1', '2'])
  end
end
