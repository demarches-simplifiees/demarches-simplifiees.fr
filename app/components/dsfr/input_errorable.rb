module Dsfr
  module InputErrorable
    extend ActiveSupport::Concern

    included do
      delegate :object, to: :@form
      delegate :errors, to: :object

      renders_one :hint

      private

      # lookup for edge case from `form.rich_text_area`
      #   rich text uses _rich_#{attribute}, but it is saved on #{attribute}, as well as error messages
      def attribute_or_rich_body
        case @input_type
        when :rich_text_area
          @attribute.to_s.sub(/\Arich_/, '').to_sym
        else
          @attribute
        end
      end

      def fr_select?
        return false if fr_fieldset?

        [
          'departements',
          'drop_down_list',
          'multiple_drop_down_list',
          'pays',
          'regions'
        ].include?(@champ.type_champ)
      end

      def fr_input?
        [
          'annuaire_education',
          'date',
          'datetime',
          'decimal_number',
          'dgfip',
          'dossier_link',
          'email',
          'iban',
          'integer_number',
          'mesri',
          'number',
          'phone',
          'piece_justificative',
          'pole_emploi',
          'rna',
          'siret',
          'text',
          'textarea',
          'titre_identite'
        ].include?(@champ.type_champ)
      end

      def fr_radio?
        [
          'boolean'
        ].include?(@champ.type_champ)
      end

      def fr_fieldset?
        @champ.dsfr_champ_container == :fieldset
      end

      def dsfr_group_classname
        if fr_fieldset?
          dsfr_input_classname
        else
          "#{dsfr_input_classname}-group"
        end
      end

      def dsfr_input_classname
        return "fr-fieldset" if fr_fieldset?
        return "fr-input" if fr_input?
        return "fr-select" if fr_select?
        return "fr-radio" if fr_radio?
      end

      def input_group_error_class_names
        {
          "#{dsfr_group_classname}--error" => errors_on_attribute?,
          "#{dsfr_group_classname}--valid" => !errors_on_attribute? && errors_on_another_attribute?
        }
      end

      def input_error_class_names
        {
          "#{dsfr_input_classname}--error": errors_on_attribute?
        }
      end

      def input_error_opts
        {
          aria: {
            describedby: describedby_id,
            invalid: errors_on_attribute?
          }
        }
      end

      def input_opts(other_opts = {})
        @opts = @opts.deep_merge!(other_opts)
        @opts[:class] = class_names(map_array_to_hash_with_true(@opts[:class])
                                      .merge({
                                        'fr-password__input': password?,
                                             'fr-input': true,
                                             'fr-mb-0': true
                                      }.merge(input_error_class_names)))

        if errors_on_attribute?
          @opts.deep_merge!(aria: {
            describedby: describedby_id,
            invalid: errors_on_attribute?
          })
        end

        if @required
          @opts[:required] = true
        end

        if email?
          @opts.deep_merge!(data: {
            action: "blur->email-input#checkEmail",
            'email-input-target': 'input'
          })
        end
        @opts
      end

      def describedby_id
        dom_id(@champ, :error_full_messages)
      end

      def errors_on_another_attribute?
        !errors.empty?
      end

      def errors_on_attribute?
        errors.has_key?(attribute_or_rich_body)
      end

      # errors helpers
      def error_full_messages
        errors.full_messages_for(attribute_or_rich_body)
      end

      def map_array_to_hash_with_true(array_or_string_or_nil)
        Array(array_or_string_or_nil).to_h { [_1, true] }
      end

      def hint
        get_slot(:hint).presence || default_hint
      end

      def default_hint
        I18n.t("activerecord.attributes.#{object.class.name.underscore}.hints.#{@attribute}")
      end

      def password?
        false
      end

      def email?
        false
      end

      def hint?
        return true if get_slot(:hint).present?

        I18n.exists?("activerecord.attributes.#{object.class.name.underscore}.hints.#{@attribute}")
      end
    end
  end
end
