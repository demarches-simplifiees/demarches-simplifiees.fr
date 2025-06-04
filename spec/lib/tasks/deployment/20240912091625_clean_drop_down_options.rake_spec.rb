# frozen_string_literal: true

describe '20240912091625_clean_drop_down_options.rake' do
  let(:rake_task) { Rake::Task['after_party:clean_drop_down_options'] }

  let!(:dashed_drop_down_list) do
    drop_down_list_value = ['1', '-- nop --', '2'].join("\r\n")
    create(:type_de_champ_drop_down_list, drop_down_list_value:)
  end

  let!(:witness_drop_down_list) do
    drop_down_list_value = ['1', 'hi', '2'].join("\r\n")
    create(:type_de_champ_drop_down_list, drop_down_list_value:)
  end

  let!(:multiple_drop_down_list) do
    drop_down_list_value = ['1', '-- nop --', '2'].join("\r\n")
    create(:type_de_champ_multiple_drop_down_list, drop_down_list_value:)
  end

  before do
    rake_task.invoke

    [dashed_drop_down_list, witness_drop_down_list, multiple_drop_down_list].each(&:reload)
  end

  after { rake_task.reenable }

  it 'removes the hidden options' do
    expect(dashed_drop_down_list.drop_down_list_value).to eq(['1', '2'].join("\r\n"))
    expect(witness_drop_down_list.drop_down_list_value).to eq(['1', 'hi', '2'].join("\r\n"))
    expect(multiple_drop_down_list.drop_down_list_value).to eq(['1', '2'].join("\r\n"))
  end
end
