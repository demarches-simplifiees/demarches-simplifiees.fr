# frozen_string_literal: true

describe '20240917131034_remove_empty_options_from_drop_down_list.rake' do
  let(:rake_task) { Rake::Task['after_party:remove_empty_options_from_drop_down_list'] }

  let!(:drop_down_list_with_empty_option) do
    create(:type_de_champ_drop_down_list, drop_down_options: ['', '1', '2'])
  end

  let!(:drop_down_list_with_other_empty_option) do
    create(:type_de_champ_drop_down_list, drop_down_options: ['1', '', '2', ''])
  end

  let!(:witness_drop_down_list) do
    create(:type_de_champ_drop_down_list, drop_down_options: ['1', '2'])
  end

  before do
    rake_task.invoke

    [
      drop_down_list_with_empty_option,
      drop_down_list_with_other_empty_option,
      witness_drop_down_list
    ].each(&:reload)
  end

  after { rake_task.reenable }

  it 'removes the empty option' do
    expect(drop_down_list_with_empty_option.drop_down_options).to eq(['1', '2'])
    expect(drop_down_list_with_other_empty_option.drop_down_options).to eq(['1', '2'])
    expect(witness_drop_down_list.drop_down_options).to eq(['1', '2'])
  end
end
