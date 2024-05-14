# frozen_string_literal: true

describe '20221221155508_normalize_yes_no_values' do
  shared_examples "a yes_no value normalizer" do |value, expected_value|
    let(:rake_task) { Rake::Task['after_party:normalize_yes_no_values'] }
    let(:yes_no) { create(:champ_yes_no) }

    subject(:run_task) { rake_task.invoke }

    context "when the value is #{value}" do
      before do
        yes_no.value = value
        yes_no.save(validate: false)
      end

      after { rake_task.reenable }

      it "normalizes the value to #{expected_value}" do
        expect { run_task }.to change { yes_no.reload.value }.from(value).to(expected_value)
      end
    end
  end

  it_behaves_like 'a yes_no value normalizer', '', nil
  it_behaves_like 'a yes_no value normalizer', 'random value', 'false'
end
