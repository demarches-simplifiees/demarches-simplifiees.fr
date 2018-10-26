require 'spec_helper'

describe '2018_03_06_clean_html_textareas#clean' do
  let(:procedure) { create(:procedure) }
  let(:type_champ) { create(:type_de_champ_textarea, procedure: procedure) }
  let(:champ) { type_champ.champ.create(value: "<p>Gnahar<br>greu bouahaha</p>") }
  let(:champ_date) { Time.zone.local(1995) }
  let(:rake_date) { Time.zone.local(2018) }
  let(:rake_task) { Rake::Task['2018_03_06_clean_html_textareas:clean'] }

  before do
    Timecop.freeze(champ_date) { champ }
    Timecop.freeze(rake_date) { rake_task.invoke }
    champ.reload
  end

  after { rake_task.reenable }

  it 'cleans up html tags' do
    expect(champ.value).to eq("Gnahar\ngreu bouahaha\n")
  end

  it 'does not change the model’s dates' do
    expect(champ.updated_at).to eq(champ_date)
  end
end
