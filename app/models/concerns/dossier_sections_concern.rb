module DossierSectionsConcern
  extend ActiveSupport::Concern

  included do
    def sections_for(champ)
      @sections = Hash.new do |hash, parent|
        case parent
        when :public
          hash[parent] = champs_public.filter(&:header_section?)
        when :private
          hash[parent] = champs_private.filter(&:header_section?)
        else
          hash[parent] = parent.champs.filter(&:header_section?)
        end
      end
      @sections[champ.parent || (champ.public? ? :public : :private)]
    end

    def auto_numbering_section_headers_for?(champ)
      # pf : historically, headers in repetiion are numbered so apply numbering in repetitions
      # return false if champ.child?

      sections_for(champ)&.none?(&:libelle_with_section_index?)
    end

    def index_for_section_header(champ)
      champs = champ.private? ? champs_private : champs_public
      index = 1
      champs.each do |c|
        if c.repetition?
          index_in_repetition = c.rows.flatten.filter { _1.stable_id == champ.stable_id }.find_index(champ)
          return "#{index}.#{index_in_repetition + 1}" if index_in_repetition
        else
          return index if c.stable_id == champ.stable_id
          next unless c.visible?

          index += 1 if c.type_de_champ.header_section?
        end
      end
      index
    end
  end
end
