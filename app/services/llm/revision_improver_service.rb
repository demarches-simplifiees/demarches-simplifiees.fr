# frozen_string_literal: true

module LLM
  class RevisionImproverService
    JSON_SCHEMA = Rails.root.join("config/llm/revision_improver_operations_json_schema.json").read

    attr_reader :llm
    attr_reader :assistant
    attr_reader :procedure
    attr_accessor :now

    def initialize(procedure)
      @llm = OpenAIClient.instance
      @procedure = procedure
      @now = Time.zone.now.to_i

      @assistant = Langchain::Assistant.new(llm:) do |response_chunk|
        print response_chunk.dig("delta", "content")
      end

      @assistant.add_message(role: "system", content: system_prompt)
    end

    def analyze(attempt = 0)
      # log_prompt

      llm.chat_parameters.update(temperature: { default: 1.0 }, max_tokens: { default: 8192 * 2 })
      assistant.add_messages(messages: messages_analyze)
      assistant.run!

      backup_response(:analysis)
    end

    def insert_analysis(analysis)
      assistant.add_messages(messages: messages_analyze)
      assistant.add_message(role: "assistant", content: analysis)
    end

    def suggest(attempt = 0)
      # log_prompt
      #

      llm.chat_parameters.update(temperature: { default: 0.1 }, repetition_penalty: { default: 0 }, max_tokens: { default: 8192 * 2 })
      assistant.add_messages(messages: messages_suggest)
      assistant.run!

      backup_response(:suggest)

      parser.parse(assistant.messages.last.content).symbolize_keys
    rescue Langchain::OutputParsers::OutputParserException, JSON::Schema::ValidationError => e
      raise e # if attempt >= 2
    # puts "Failure #{e.message}, retry ##{attempt}"
    # Rails.logger.info { "Failure #{e.message}, retry ##{attempt}" }
    # suggest(attempt + 1)
    rescue => e
      binding.irb
    end

    private

    def messages_analyze
      [
        { role: "user", content: current_schema_prompt },
        { role: "user", content: analyze_prompt }
      ]
    end

    def messages_suggest
      [
        { role: "user", content: format(restructure_prompt, json_schema: parser.get_format_instructions) }
      ]
    end

    def parser
      @parser ||= Langchain::OutputParsers::StructuredOutputParser.from_json_schema(JSON_SCHEMA)
    end

    def current_schema_prompt
      template = <<~PROMPT
        Here is the form schema you need to analyze:

        <form_schema>
          %<schema>s
        </form_schema>

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

    def analyze_prompt
      <<~PROMPT
        Read carefully these guidelines:
          1. Field Types: Use the appropriate field type from the following list:
            - header_section: For organizing form sections (no user input)
            - repetition: For repeatable blocks of children fields. User can repeat children fields as many times as he wants.
            - explication: For providing context or instructions (no user input)
            - civilite: For selecting "Madame" or "Monsieur". Administration already knows civilite of user
            - email: For email addresses. Administration already knows email of user
            - phone: For phone numbers
            - address: For postal addresses (auto-completed with additional info: commune name and codes, code postal, departement name and code)
            - communes: For selecting French communes (auto-completed with additional info: code, code postal, departement name and code)
            - departments: For selecting French departments
            - text: For short text inputs
            - textarea: For longer text inputs
            - integer_number: For whole numbers
            - decimal_number: For numbers with decimals
            - date: For date selection
            - piece_justificative: For document uploads. Do not wrap in a repetition because it supports multiple documents
            - titre_identite: For secure identity document uploads
            - checkbox: For single checkboxes
            - yes_no: For yes/no questions
            - drop_down_list: For single-choice selections. Choices are configured by administration separately
            - multiple_drop_down_list: For multiple-choice selections. Choices are configured by administration separately

          2. Labeling and Descriptions:
            - Use proper capitalization in labels and descriptions (ie. not in uppercase). This is crucial.
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
            - Add header sections to structure the fields with appropriate level if necessary (level starts at 1)
            - Apply visibility conditions to dynamically show/hide a field based on another field's exact choice or value. When a field is hidden by its visibility condition, its mandatory rule will be ignored
            - Use checkboxes for consent fields
            - Consider information automatically retrieved by certain field types (e.g., address, communes) to avoid redundant questions. This is your main goal.

          4. Mandatory Fields:
            - By default, all input fields are considered mandatory (mandatory = true)
            - Explicitly set mandatory = false for optional fields

        Please analyze the form schema and provide recommendations for improvements. Follow these steps:

        1. Analyze the overall form structure.
        2. For each field in the form:
            a. Determine carefully if the field should be deleted, updated, or kept as is
            b. Delete if:
              - Identifed as redundant with another field
              - Data is already known by the administration (e.g., email, first name of user, postal code when there's an address field)
              - the field should be part of a `repetition` structure instead
            c. Update if:
              - the label or description is unclear or inappropriate
              - the label is in uppercase : update field with a proper case
              - field's visibility should be conditioned by the value of a previous field
              - field type is not appropriate
              - Ensure compliance with guidelines
        3. Identify where header sections could be added to improve the form structure.
        4. Review official recommendations for French administrative forms and note any potential compliance issues

        Structure your analysis in a <analysis> tags.
        It's OK for this section to be quite long.
      PROMPT
    end

    def restructure_prompt
      <<~PROMPT
        Based on your previous analysis, structure ALL fields in a JSON format following this schema:
        %<json_schema>s

        CRITICAL RULES for field processing:
        1. You MUST include ALL original fields in your response, distributed between:
           - "delete" category
           - "update" category

        2. When a field is added to a repetition structure:
           - You MUST delete ALL original standalone versions
           - This deletion MUST be documented in the "delete" category
           - Use justification: "Remplacé par un bloc répétable dynamique"

        3. For each field in "update" category:
           - If modifications needed: specify only the changing attributes
           - Update label with a proper case
           - If no modifications needed: skip justification
           - But ALWAYS list the field

        Remember previous analysis guidelines:
        - Keep relevant repetition structures identified
        - Preserve planned improvements to descriptions
        - Follow French administrative standards
        - Keep identified redundancy removals
        - Answer labels, descriptions, summary, justification in french.

        Response structure:
        {
          "delete": [
            - ALL deleted fields, including all those moved to repetition
            - Clear justification for each deletion
          ],
          "update": [
            - ALL remaining fields, including unchanged ones
            - For modified fields: only changed attributes and a justification
          ],
          "summary": {
            - Brief French summary of implemented changes
            - Focus on structural improvements
          }
        }
      PROMPT
    end

    # def log_prompt
    #   File.write(
    #     "tmp/procedure_#{procedure.id}_#{now}_prompt.json",
    #     JSON.pretty_generate(messages)
    #   )

    #   Rails.logger.info { "Prompt written in tmp/llm/procedure_#{procedure.id}_prompt.json" }
    # end

    def backup_response(part)
      File.write(
        "tmp/llm/procedure_#{procedure.id}_#{now}_#{part}.txt",
          assistant.messages.last.content
      )
    end
  end
end
