FactoryGirl.define do
  factory :preference_list_dossier do
    libelle 'Procedure'
    table 'procedure'
    attr 'libelle'
    attr_decorate 'libelle'
    order nil
    filter nil
    bootstrap_lg 1
  end
end
