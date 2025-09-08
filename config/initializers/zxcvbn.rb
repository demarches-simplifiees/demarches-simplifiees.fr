# frozen_string_literal: true

module ZxcvbnExtension
  # Apprend our own lists to default gem lists
  # https://github.com/formigarafa/zxcvbn-rb/blob/master/lib/zxcvbn/frequency_lists.rb
  # They are loazy loaded at first use, then kept in memory through ZxcvbnService.
  def frequency_lists
    base_lists = super

    custom_lists = load_custom_frequency_lists

    base_lists.merge(custom_lists)
  end

  private

  def load_custom_frequency_lists
    custom_list_names = ['words_fr', 'passwords_fr', 'surnames_fr', 'female_names_fr', 'male_names_fr']

    custom_list_names.each_with_object({}) do |name, lists|
      custom_path = Rails.root.join("config/zxcvbn_frequency_lists/#{name}.txt")
      lists[name] = file_enumerator(custom_path)
    end
  end
end

Zxcvbn.singleton_class.prepend(ZxcvbnExtension)
