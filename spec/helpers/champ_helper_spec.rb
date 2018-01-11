require 'rails_helper'

RSpec.describe ChampHelper, type: :helper do
  shared_examples 'champ_formatter' do |type_champ, value, output|
    let(:type_de_champ_public) { create(:type_de_champ_public, type_champ) }
    let(:champ) { Champ.new(type_de_champ: type_de_champ_public, value: value) }

    it { is_expected.to eq(output) }
  end

  shared_examples 'yes_no_formatter' do |yes_output, no_output, nil_output|
    it_should_behave_like 'champ_formatter', :yes_no, 'true', yes_output
    it_should_behave_like 'champ_formatter', :yes_no, 'false', no_output
    it_should_behave_like 'champ_formatter', :yes_no, nil, nil_output
  end

  shared_examples 'checkbox_formatter' do |on_output, empty_string_output, nil_output|
    it_should_behave_like 'champ_formatter', :checkbox, 'on', on_output
    it_should_behave_like 'champ_formatter', :checkbox, '', empty_string_output
    it_should_behave_like 'champ_formatter', :checkbox, nil, nil_output
  end

  shared_examples 'civilite_formatter' do |m_output, mme_output, nil_output|
    it_should_behave_like 'champ_formatter', :civilite, 'M.', m_output
    it_should_behave_like 'champ_formatter', :civilite, 'Mme', mme_output
    it_should_behave_like 'champ_formatter', :civilite, nil, nil_output
  end

  shared_examples 'engagement_formatter' do |on_output, empty_string_output, nil_output|
    it_should_behave_like 'champ_formatter', :engagement, 'on', on_output
    it_should_behave_like 'champ_formatter', :engagement, '', empty_string_output
    it_should_behave_like 'champ_formatter', :engagement, nil, nil_output
  end

  describe '.formatted_value' do
    subject { formatted_value(champ) }

    it_should_behave_like 'champ_formatter', :text, '123', '123'

    it_should_behave_like 'champ_formatter', :textarea, '<b>gras<b>', '<b>gras<b>'

    it_should_behave_like 'champ_formatter', :date, '2017-12-31', '31/12/2017'

    it_should_behave_like 'champ_formatter', :datetime, '13/09/2017 09:00', '13/09/2017 09:00'

    it_should_behave_like 'champ_formatter', :number, '99', '99'
    it_should_behave_like 'champ_formatter', :number, '', ''
    it_should_behave_like 'champ_formatter', :number, nil, ''

    it_should_behave_like 'checkbox_formatter', 'on', '', ''

    it_should_behave_like 'civilite_formatter', 'M.', 'Mme', ''

    it_should_behave_like 'champ_formatter', :email, 'michel@tps.fr', 'michel@tps.fr'
    it_should_behave_like 'champ_formatter', :email, nil, ''

    it_should_behave_like 'champ_formatter', :phone, '0326673831', '0326673831'
    it_should_behave_like 'champ_formatter', :phone, '', ''
    it_should_behave_like 'champ_formatter', :phone, nil, ''

    it_should_behave_like 'champ_formatter', :address, '35 rue saint dominique 75007 Paris', '35 rue saint dominique 75007 Paris'
    it_should_behave_like 'champ_formatter', :address, nil, ''

    it_should_behave_like 'yes_no_formatter', 'true', 'false', ''

    it_should_behave_like 'champ_formatter', :drop_down_list, 'Autres activités de services', 'Autres activités de services'
    it_should_behave_like 'champ_formatter', :drop_down_list, nil, ''

    it_should_behave_like 'champ_formatter', :multiple_drop_down_list, '["test", "voila"]', 'test, voila'

    it_should_behave_like 'champ_formatter', :regions, 'Île-de-France', 'Île-de-France'
    it_should_behave_like 'champ_formatter', :regions, nil, ''

    it_should_behave_like 'champ_formatter', :departements, '06 - Alpes-Maritimes', '06 - Alpes-Maritimes'
    it_should_behave_like 'champ_formatter', :departements, nil, ''

    it_should_behave_like 'engagement_formatter', 'on', '', ''

    it_should_behave_like 'champ_formatter', :header_section, nil, ''

    it_should_behave_like 'champ_formatter', :explication, nil, ''

    it_should_behave_like 'champ_formatter', :dossier_link, '12345', '12345'
    it_should_behave_like 'champ_formatter', :dossier_link, '', ''
    it_should_behave_like 'champ_formatter', :dossier_link, nil, ''
  end

  # describe 'for_export' do
  #   subject { champ.for_export }

  #   it_should_behave_like 'champ_formatter', :text, '123', '123'

  #   it_should_behave_like 'champ_formatter', :textarea, '<b>gras<b>', 'gras'

  #   it_should_behave_like 'champ_formatter', :date, '2017-12-31', '2017-12-31'

  #   it_should_behave_like 'champ_formatter', :datetime, '13/09/2017 09:00', '13/09/2017 09:00'

  #   it_should_behave_like 'champ_formatter', :number, '99', '99'
  #   it_should_behave_like 'champ_formatter', :number, '', nil
  #   it_should_behave_like 'champ_formatter', :number, nil, nil

  #   it_should_behave_like 'checkbox_formatter', 'on', nil, nil

  #   it_should_behave_like 'civilite_formatter', 'M.', 'Mme', nil

  #   it_should_behave_like 'champ_formatter', :email, 'michel@tps.fr', 'michel@tps.fr'
  #   it_should_behave_like 'champ_formatter', :email, nil, nil

  #   it_should_behave_like 'champ_formatter', :phone, '0326673831', '0326673831'
  #   it_should_behave_like 'champ_formatter', :phone, '', nil
  #   it_should_behave_like 'champ_formatter', :phone, nil, nil

  #   it_should_behave_like 'champ_formatter', :address, '35 rue saint dominique 75007 Paris', '35 rue saint dominique 75007 Paris'
  #   it_should_behave_like 'champ_formatter', :address, nil, nil

  #   it_should_behave_like 'yes_no_formatter', 'oui', 'non', nil

  #   it_should_behave_like 'champ_formatter', :drop_down_list, 'Autres activités de services', 'Autres activités de services'
  #   it_should_behave_like 'champ_formatter', :drop_down_list, nil, nil

  #   it_should_behave_like 'champ_formatter', :multiple_drop_down_list, '["test", "voila"]', 'test, voila'

  #   it_should_behave_like 'champ_formatter', :pays, 'FRANCE', 'FRANCE'
  #   it_should_behave_like 'champ_formatter', :pays, nil, nil

  #   it_should_behave_like 'champ_formatter', :regions, 'Île-de-France', 'Île-de-France'
  #   it_should_behave_like 'champ_formatter', :regions, nil, nil

  #   it_should_behave_like 'champ_formatter', :departements, '06 - Alpes-Maritimes', '06 - Alpes-Maritimes'
  #   it_should_behave_like 'champ_formatter', :departements, nil, nil

  #   it_should_behave_like 'engagement_formatter', 'on', nil, nil

  #   it_should_behave_like 'champ_formatter', :header_section, nil, nil

  #   it_should_behave_like 'champ_formatter', :explication, nil, nil

  #   it_should_behave_like 'champ_formatter', :dossier_link, '12345', '12345'
  #   it_should_behave_like 'champ_formatter', :dossier_link, '', nil
  #   it_should_behave_like 'champ_formatter', :dossier_link, nil, nil
  # end
end
