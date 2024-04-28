# frozen_string_literal: true

describe '20221221153640_normalize_checkbox_values' do
  shared_examples "a checkbox value normalizer" do |value, expected_value|
    let(:rake_task) { Rake::Task['after_party:normalize_checkbox_values'] }
    let(:checkbox) { create(:champ_checkbox) }

    subject(:run_task) { rake_task.invoke }

    context "when the value is #{value}" do
      before do
        checkbox.value = value
        checkbox.save(validate: false)
      end

      after { rake_task.reenable }

      it "normalizes the value to #{expected_value}" do
        expect { run_task }.to change { checkbox.reload.value }.from(value).to(expected_value)
      end
    end
  end

  it_behaves_like 'a checkbox value normalizer', '', nil
  it_behaves_like 'a checkbox value normalizer', 'on', 'true'
  it_behaves_like 'a checkbox value normalizer', 'off', 'false'
  it_behaves_like 'a checkbox value normalizer', 'random value', 'false'
end
