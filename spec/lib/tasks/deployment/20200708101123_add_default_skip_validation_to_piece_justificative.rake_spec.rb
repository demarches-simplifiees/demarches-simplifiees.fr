# frozen_string_literal: true

describe '20200708101123_add_default_skip_validation_to_piece_justificative.rake' do
  let(:rake_task) { Rake::Task['after_party:add_default_skip_validation_to_piece_justificative'] }
  let!(:pj_type_de_champ) { create(:type_de_champ_piece_justificative) }
  let!(:text_type_de_champ) { create(:type_de_champ_text) }

  before do
    rake_task.invoke
    text_type_de_champ.reload
    pj_type_de_champ.reload
  end

  after { rake_task.reenable }

  context 'on a piece_justificative type de champ' do
    it 'sets the skip_pj_validation option' do
      expect(pj_type_de_champ.skip_pj_validation).to be_truthy
    end
  end

  context 'on a non piece_justificative type de champ' do
    it 'does not set the skip_pj_validation option' do
      expect(text_type_de_champ.skip_pj_validation).to be_blank
    end
  end
end
