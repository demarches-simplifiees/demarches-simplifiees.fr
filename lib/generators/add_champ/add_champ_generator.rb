require "tty-prompt"

class AddChampGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def make_prompt
    @prompt = TTY::Prompt.new
  end

  def create_editable_champ_component
    create_file "app/components/editable_champ/#{champ_component_base_name}.rb" do
      <<~CONTENT
        class EditableChamp::#{champ_to_class}Component < EditableChamp::EditableChampBaseComponent
        end
      CONTENT
    end
    create_file "app/components/editable_champ/#{champ_component_base_name}/#{champ_component_base_name}.html.haml" do
      <<~CONTENT
        = @form.text_field(:value, input_opts(id: @champ.input_id, required: @champ.required?, aria: { describedby: @champ.describedby_id }))
      CONTENT
    end
    directory "editable_champ", "app/components/editable_champ/#{champ_component_base_name}/"
  end

  def create_champ
    create_file "app/models/champs/#{champ_to_path}_champ.rb" do
      <<~CONTENT
        class Champs::#{champ_to_class}Champ < Champ
        end
      CONTENT
    end
  end

  def add_graphql_types
    graphql_type = "#{champ_to_class}ChampDescriptorType "
    create_file "app/graphql/types/champs/descriptor/#{champ_to_path}_champ_descriptor_type.rb" do
      <<~CONTENT
        module Types::Champs::Descriptor
          class #{graphql_type} < Types::BaseObject
            implements Types::ChampDescriptorType
          end
        end
      CONTENT
    end

    case_blk = <<~CONTENT

      when TypeDeChamp.type_champs.fetch(:#{champ_to_path})
        Types::Champs::Descriptor::#{graphql_type}
CONTENT
    insert_into_file "app/graphql/types/champ_descriptor_type.rb",
                     case_blk,
                     after: "case object.type_champ"

    insert_into_file "app/graphql/api/v2/schema.rb",
                     ",\nTypes::Champs::Descriptor::#{graphql_type}\n",
                     after: "Types::Champs::Descriptor::ExpressionReguliereChampDescriptorType"

  end

  def add_champ_to_type_de_champ
    category = @prompt.select("Ou grouper ce type de champ dans l'interface de creation de formulaire ?", ['STRUCTURE', 'ETAT_CIVIL', 'LOCALISATION', 'PAIEMENT_IDENTIFICATION', 'STANDARD', 'PIECES_JOINTES', 'CHOICE', 'REFERENTIEL_EXTERNE'])
    insert_into_file "app/models/type_de_champ.rb",
                     "\n    #{champ_to_path}: #{category},\n",
                     after: "TYPE_DE_CHAMP_TO_CATEGORIE = {"
    insert_into_file "app/models/type_de_champ.rb",
                     "\n    #{champ_to_path}: '#{champ_to_path}',\n",
                     after: "enum type_champs: {"
  end

  def create_type_de_champ
    create_file "app/models/types_de_champ/#{champ_to_path}_type_de_champ.rb" do
     <<~CONTENT
       class TypesDeChamp::#{champ_to_class}TypeDeChamp < TypesDeChamp::TypeDeChampBase
       end
      CONTENT
   end
  end

  def add_to_type_de_champs_factory
    factory = <<~CONTENT
      factory :type_de_champ_#{champ_to_path} do
        type_champ { TypeDeChamp.type_champs.fetch(:#{champ_to_path}) }
      end
    CONTENT
    insert_into_file "spec/factories/type_de_champ.rb",
                     factory,
                     before: 'factory :type_de_champ_cojo do'
  end

  def add_champ_factory
    factory = <<~CONTENT
      factory :champ_#{champ_to_path}, class: 'Champs::#{name.camelize}Champ' do
        type_de_champ { association :type_de_champ_#{champ_to_path}, procedure: dossier.procedure }
      end
    CONTENT
    insert_into_file "spec/factories/champ.rb",
                     factory,
                     before: 'factory :champ_cojo'
  end

  def dump_sql_schema
    run "rake graphql:schema:dump"
  end

  def rubocopify_generate_files
    run "rubocop -A #{list_generated_content.join(' ')}"
  end

  def add_to_git
    if @prompt.yes?("Souhaitez vous ajouter le champs a l'index git ?")
      run "git add #{list_generated_content.join(" ")}"
    end
  end

  private

  def champ_to_path
    @name.underscore
  end

  def champ_to_class
    @name.camelize
  end

  def champ_component_base_name
    "#{champ_to_path}_component"
  end

  def list_generated_content
    [
      "app/components/editable_champ/*",
      "app/models/champs/#{champ_to_path}_champ.rb",
      "app/graphql/types/champs/descriptor/#{champ_to_path}_champ_descriptor_type.rb",
      "app/models/types_de_champ/#{champ_to_path}_type_de_champ.rb",

      "app/graphql/types/champ_descriptor_type.rb",
      "app/graphql/api/v2/schema.rb",
      "app/models/type_de_champ.rb",
      "spec/factories/type_de_champ.rb",
      "spec/factories/champ.rb"
    ]
  end
end
