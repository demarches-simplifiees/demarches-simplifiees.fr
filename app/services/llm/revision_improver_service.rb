# frozen_string_literal: true

module LLM
  class RevisionImproverService
    JSON_SCHEMA = Rails.root.join("config/llm/revision_improver_operations_json_schema.json").read

    attr_reader :llm
    attr_reader :procedure

    def initialize(procedure)
      # @llm = OpenAIClient.instance
      @llm = SonnetClient.instance
      @procedure = procedure
    end

    def suggest
      log_prompt

      response = if llm.is_a?(Langchain::LLM::Anthropic)
        llm.chat(messages:, system: system_prompt, max_tokens: 8192)
      else
        llm.chat(messages:)
      end

      backup_response(response)

      begin
        parser.parse(response.chat_completion).symbolize_keys
      rescue Langchain::OutputParsers::OutputParserException => e
        # TODO: retry etc…
        raise e
      end
    end

    private

    def messages
      [
        llm.is_a?(Langchain::LLM::Anthropic) ? nil : { role: :system, content: system_prompt },
        { role: :user, content: current_schema_prompt },
        { role: :user, content: ds_description_prompt },
        { role: :user, content: naming_recommendations_prompt },
        { role: :user, content: parser.get_format_instructions }
      ].compact
    end

    def parser
      @parser ||= Langchain::OutputParsers::StructuredOutputParser.from_json_schema(JSON_SCHEMA)
    end

    def current_schema_prompt
      template = <<~PROMPT
        Voici le schéma de la révision actuelle pour la démarche “%<libelle>s” :
        %<schema>s.

        Réponds avec la liste des opérations à effectuer parmi:
        - l'ajout de nouveaux champs
        - la suppression de champs
        - la mise à jour de champs existants. Inutile de lister les champs pour lesquels aucune modifiation n'est nécessaire, ou de rappeler les attributs qui ne changent pas.

        Respecte scrupuleusement les consignes et le format JSON, car le résultat sera directement interpété par une API.
      PROMPT

      format(template, libelle: procedure.libelle, schema: procedure.published_revision.schema_to_llm.to_json)
    end

    def system_prompt
      <<~PROMPT
        Tu es un assistant expert dans la création de démarches pour un site de l’administration française.
        Ce site permet à des agents de concevoir le formulaire d'une démarche afin que les usagers puissent remplir leurs dossiers.
        Le site met à disposition une variété de champs de formulaire qui permettent de structurer la démarche,
        de proposer une ergonomie adaptée à chaque type de saisie, et parfois de faire remonter automatiquement
        à l'administration des informations complémentaires.

        Ton rôle est d'aider l'agent à élaborer la meilleure démarche en respectant des règles comme :
        - la compréhension de la démarche pour tout profil d'usager, y compris les libellés
        - la réduction du nombre d'informations demandées à l'usager
        - l'ergonomie en utilisant les champs de formulaire appropriés
        - le suivi des recommandations officielles sur la façon de nommer ou ne pas nommer des informations, qui seront fournies plus loin.

        Tu peux proposer d'ajouter, retirer, modifier leurs libellés, descriptions,
        changer leur type ou le caractère obligatoire de chaque champ, ou leur condition d'affichage.

        Une bonne démarche est facile à comprendre, rapide à remplir par l'usager, et qui ne demande que les informations
        strictement utiles à l'administration.

        Tes recommandations seront proposées dans l'interface l'agent via une version améliorée de son formulaire.
      PROMPT
    end

    def ds_description_prompt
      <<~PROMPT
        ## Caractéristiques d'un champ
        - un stable id qui identifie de manière unique un champ. IMPORTANT: ne change jamais ce stable id pour un champ donné. Il est automatiquement ajouté par le site lorsqu'un champ est ajouté.
        - un type, qui détermine l'ergonomie de saisie présentée à l'usager, et dans certains cas remontera par API des informations complémentaires, comme le code commune ou le numéro de département pour le champ adresse.
        - un libellé, obligatoire, idéalement de moins de 80 caractères
        - une description, optionnelle, qui est un complément d'informations au libellé. On n'écrit que les informations strictement pertinentes et non triviales. Inutile de préciser qu'un numéro de téléphone ou un email est fait pour contacter l'usager.
        - un attribut qui matérialise une saisie obligatoire ou non
        - une condition d'affichage, optionnelle, dépendant de valeurs saisies préalablement par l'usager. Si cette condition est vraie le champ sera affiché, sinon il sera masqué, même s'il est obligatoire.
        - certains types de champs proposent d'autres options listées plus loin.

        En amont du dossier, l'usager a déjà saisi son email, prénom et nom.

        ## Types de champ

        Par défaut tous les champs de saisie sont considérés comme obligatoires (mandatory = true)

        ### Titre de section (type = header_section)
        Un titre ou sous-titre pour organiser des sections de formulaire, sans valeur à saisir.
        En option, l'attribut `level` de 1 à 3 permet de créer sous-titres. La numérotation des titres est automatique si aucun titre de la démarche ne commence par un numéro.
        Les attributs description et mandatory ne sont pas disponible.

        ### Bloc répétable (type = repetition)
        Structure contenant un ou plusieurs champs sous la clé `children` permettant à l'usager de répéter autant de fois qu'il le veut l'ensemble des champs de cette structure.
        Exemple: si l'usager doit remplir les prénoms et âge de ses enfants,
        le formulaire peut être organisé avec un bloc répétable intitulé "Enfants à charge" non obligatoire.
        A l'intérieur de ce bloc répétable, les champs `text` et `integer` permettent de saisir le prénom et âge de chacun enfant. L'usager pourra en ajouter autant que nécessaire.

        ### Explication (type = explication)
        Un texte libre fourni par l'administration qui vise à contextualiser certaines informations demandées à l'usager. L'usager ne saisira pas d'information.
        Seul le libellé et la description sont possibles.

        ### Civilité (type = civilite)
        Représenté par un bouton radio avec lex choix "Madame" et "Monsieur".

        ### Adresse électronique (type = email)
        Représenté en html comme un input de type text, avec validation de format d'un email

        ### Téléphone (type = phone)
        Accepte un numéro de téléphone valide.

        ### Adresse (type = address)
        Champ de saisie d'adresse postale, représenté par un combobox avec autocompletion par la Base d'Adresses Nationales.
        Les informations complémentaires sont remontées à l'administration :
        - numéro de voie, nom de voie, code postal, nom de la commune, code INSEE de la commune, nom de département, numéro de département, nom de la région, numéro de la région

        ### Commune (type = communes)
        Champ de saisie de de commune, représenté par un combobox avec autocompletion parmi les communes françaises.
        Les informations complémentaires sont remontées à l'administration :
        - code INSEE de la commune, nom de département, numéro de département, nom de la région, numéro de la région

        ### Département (type = departments)
        Liste déroulante des départements français.
        Les informations complémentaires sont remontées à l'administration :
        - nom de département, numéro de département, nom de la région, numéro de la région

        ### Texte court (type = text)
        Représenté en html comme un input de type text.

        ### Texte long (type = textarea)
        Représenté en html comme un textarea.

        ### Date (type = date)
        Représenté sous forme de datepicker.

        ### Pièce justificative (type = piece_justificative)
        Permet à l'usager d'envoyer d'1 à 10 documents, dans la limite de 200 Mo par document. Tous les formats sont acceptés.

        ### Titre d'identité (type = titre_identite)
        Permet à l'usager d'envoyer un fichier PDF ou une image représentant un titre d'identité. Ce document sera hébergé de manière sécurisée.

        ### Case à cocher seule (type = checkbox)
        Représenté sous forme de checkbox.

        ### Choix simple (type = drop_down_list)
        Représenté sous forme de liste déroulante ou de combobox avec autocomplétion suivant le nombre de propositions.

        ### Choix multiple (type = multiple_drop_down_list)
        Représenté sous forme de chechbox ou ou de combobox avec choix multiples suivant le nombre de propositions.

        ### Oui/Non (type = yes_no)
        Représenté sous forme de bouton radio avec les choix "Oui" et "Non"
      PROMPT
    end

    def naming_recommendations_prompt
      # TODO
      <<~PROMPT
        ## Instructions pour un meilleur nommage et choix de champ
        - éviter les libéllée en lettres majuscules
        - les consentements, etc… doivent être matérialisés par une case à cocher
        - ne pas demander de champs inutiles ou redondants, surtout si l'administration a déjà connaissance des informations en question
        - n'hésite pas à proposer des changements pour te rapprocher des meilleurs pratiques en terme d'ergonomie
      PROMPT
    end

    def log_prompt
      File.write(
        "tmp/procedure_#{procedure.id}_prompts.json",
        JSON.pretty_generate(messages)
      )

      Rails.logger.info { "Prompt written in tmp/procedure_#{procedure.id}_prompts.json" }
    end

    def backup_response(response)
      File.write(
        "tmp/procedure_#{procedure.id}_improvements.txt",
        response.chat_completion
      )
    end
  end
end
