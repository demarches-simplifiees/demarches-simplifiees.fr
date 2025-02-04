# frozen_string_literal: true

module LLM
  class RevisionImproverService
    JSON_SCHEMA = Rails.root.join("config/llm/revision_improver_operations_json_schema.json").read

    attr_reader :llm
    attr_reader :procedure

    def initialize(procedure)
      @llm = OpenAIClient.instance
      @procedure = procedure
    end

    def suggest(attempt = 0)
      log_prompt

      response = if llm.is_a?(Langchain::LLM::Anthropic)
        llm.chat(messages:, system: system_prompt, max_tokens: 4096)
      else
        llm.chat(messages:, structured_outputs: true, max_tokens: 8192)
      end

      backup_response(response)

      parser.parse(response.chat_completion).symbolize_keys
    rescue Langchain::OutputParsers::OutputParserException, JSON::Schema::ValidationError => e
      raise e if attempt >= 3
      Rails.logger.info { "Failure #{e.message}, retry ##{attempt}" }
      suggest(attempt + 1)
    end

    private

    def messages
      [
        llm.is_a?(Langchain::LLM::Anthropic) ? nil : { role: :system, content: system_prompt },
        { role: :user, content: current_schema_prompt },
        { role: :user, content: format(ds_description_prompt, json_schema: parser.get_format_instructions) }
      ].compact
    end

    def parser
      @parser ||= Langchain::OutputParsers::StructuredOutputParser.from_json_schema(JSON_SCHEMA)
    end

    def current_schema_prompt
      template = <<~PROMPT
        Here's the current schema of the form:

        <current_schema>
          %<schema>s
        </current_schema>

        Here's the administrative procedure you'll be working on:
        <demarche_libelle>
          %<libelle>s
        </demarche_libelle>

        The applicant's email address, civility, first name, and last name are already known to administration and should not be requested again.
      PROMPT

      format(template, libelle: procedure.libelle, schema: procedure.published_revision.schema_to_llm.to_json)
    end

    def system_prompt
      <<~PROMPT
        You are an AI assistant specialized in optimizing online forms for French administrative procedures.
        Your task is to analyze and improve a given form schema, making it more user-friendly,
        efficient, and compliant with official recommendations.
      PROMPT
    end

    def ds_description_prompt
      <<~PROMPT
        Before making any recommendations, please analyze the current form structure and fields.
        Wrap your private analysis inside <analysis></analysis> tags, focusing on the following aspects:

          1. List all fields having potential issues
          2. For each field evaluate:
             - Delete if:
               - Redundant with other or data already known by administration
               - Part of a repeating field (add these in a new `repetition` field)
             - Modify if:
               - Unclear or inappropriate label/description
               - Inappropriate type
               - Non-compliant with guidelines
          3. Justify each proposed change

        After your analysis, answer with all theses recommendations in a JSON format that adheres to the following schema.
        Only update attributes or fields having changes.

        %<json_schema>s

        Important guidelines:
        1. Field Types: Use the appropriate field type from the following list:
           - header_section: For organizing form sections (no user input)
           - repetition: For repeatable blocks of children fields
           - explication: For providing context or instructions (no user input)
           - civilite: For selecting "Madame" or "Monsieur"
           - email: For email addresses
           - phone: For phone numbers
           - address: For postal addresses (auto-completes with additional info: commune name and codes, code postal, departement name and code)
           - communes: For selecting French communes (auto-completes with additional info: code, code postal, departement name and code)
           - departments: For selecting French departments
           - text: For short text inputs
           - textarea: For longer text inputs
           - integer_number: For whole numbers
           - decimal_number: For numbers with decimals
           - date: For date selection
           - piece_justificative: For document uploads. Can natively upload multiple documents.
           - titre_identite: For secure identity document uploads
           - checkbox: For single checkboxes
           - yes_no: For yes/no questions
           - drop_down_list: For single-choice selections. Choices are already configured by agents.
           - multiple_drop_down_list: For multiple-choice selections. Choices are already configured by agents.

        2. Labeling and Descriptions:
           - Use proper capitalization in labels and descriptions. This is crucial.
           - Use consistent, plain language throughout the form
           - Make labels clear and understandable for all users
           - Avoid abbreviations, acronyms, and technical jargon
           - Maintain consistent pronouns ("Vous" or "Nous") when addressing users
           - Replace negative constructions with positive, action-oriented statements
           - Keep sentences short with one idea per sentence
           - Structure all headings and labels uniformly
           - Provide descriptions only when necessary to clarify the field's purpose or requirements. Descriptions must not be redundant to labels and must not contain formatting exemples or choices.
           - Avoid trivial or redundant descriptions with labels. They must be really useful.
           - Write in active voice using present tense
           - Start conditional statements with the condition
           - Use standardized field labels (e.g., "Adresse email" not "Adresse de courrier électronique")
           - Specify document requirements clearly (format, validity, original vs copy)

        3. Form Structure:
           - Place essential fields first, following user-centric logic
           - Remove any fields asking for information already known to the administration. This is absolutely crucial.
           - Minimize the number of required documents
           - Use checkboxes for consent fields
           - Consider information automatically retrieved by certain field types (e.g., address, communes) to avoid redundant questions. This is your main goal.

        4. Mandatory Fields:
           - By default, all input fields are considered mandatory (mandatory = true)
           - Explicitly set mandatory = false for optional fields

        Remember to provide a summary explaining your recommended changes in the "summary" field of your JSON response.
        Answer summary and procedure text in french.

        <example_valid_labels>
          - Justificatif de domicile
          - Date des travaux
        </example_valid_labels>

        <example_invalid_labels>
          - NATURE DES PRESTATIONS
          - ACTIVITE DE LA STRUCTURE
        </example_invalid_labels>

        <example_valid_descriptions>
          - Daté de moins de 3 mois
          - Lisible, non raturé, à l'adresse du demandeur
        </example_valid_descriptions>

        <example_invalid_descriptions>
          - Pour vous contacter
          - Choisissez parmi "Ain", "Loire"
          - Écrivez la date
        </example_invalid_descriptions>


      PROMPT
    end

    def log_prompt
      File.write(
        "tmp/procedure_#{procedure.id}_prompt.json",
        JSON.pretty_generate(messages)
      )

      Rails.logger.info { "Prompt written in tmp/procedure_#{procedure.id}_prompt.json" }
    end

    def backup_response(response)
      File.write(
        "tmp/procedure_#{procedure.id}_improvements.txt",
        response.chat_completion
      )
    end
  end
end
