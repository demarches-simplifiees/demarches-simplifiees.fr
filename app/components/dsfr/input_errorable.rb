# frozen_string_literal: true

module Dsfr
  module InputErrorable
    extend ActiveSupport::Concern

    included do
      delegate :object, to: :@form
      delegate :errors, to: :object

      renders_one :hint

      def dsfr_group_classname
        if dsfr_champ_container == :fieldset
          'fr-fieldset'
        elsif dsfr_input_classname.present? # non fillable element
          "#{dsfr_input_classname}-group"
        end
      end

      def input_group_error_class_names
        return {} if dsfr_group_classname.nil?

        {
          "#{dsfr_group_classname}--error" => errors_on_attribute?,
          "#{dsfr_group_classname}--valid" => !errors_on_attribute? && errors_on_another_attribute?
        }
      end

      def errors_on_attribute?
        errors.has_key?(attribute_or_rich_body)
      end

      # errors helpers
      def error_full_messages
        errors.full_messages_for(attribute_or_rich_body)
      end

      def fieldset_error_opts
        if dsfr_champ_container == :fieldset && errors_on_attribute?
          { aria: { labelledby: "#{describedby_id} #{object.labelledby_id}" } }
        else
          {}
        end
      end

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

      def fr_fieldset?
        !['fr-input', 'fr-radio', 'fr-select'].include?(dsfr_input_classname)
      end

      def input_error_class_names
        {
          "#{dsfr_input_classname}--error": errors_on_attribute?
        }
      end

      def input_error_opts
        {
          aria: {
            describedby: describedby_id
          }
        }
      end

      def react_input_opts(other_opts = {})
        input_opts(other_opts, true)
      end

      def input_opts(other_opts = {}, react = false)
        @opts = @opts.deep_merge!(other_opts)
        @opts[react ? :class_name : :class] = class_names(map_array_to_hash_with_true(@opts[:class])
                                      .merge({
                                        'fr-password__input': password?,
                                             'fr-input': !react,
                                             'fr-mb-0': true
                                      }.merge(input_error_class_names)))
        if errors_on_attribute?
          @opts.deep_merge!('aria-describedby': describedby_id)
        elsif hintable?
          @opts.deep_merge!('aria-describedby': hint_id)
        end

        if @required
          @opts[react ? :is_required : :required] = true
        end

        if email?
          @opts.deep_merge!(data: {
            action: "blur->email-input#checkEmail",
            'email-input-target': 'input'
          })
        end

        @opts.deep_merge!(data: { controller: token_list(@opts.dig(:data, :controller), 'autoresize' => autoresize?) })

        @opts
      end

      def errors_on_another_attribute?
        !errors.empty?
      end

      def map_array_to_hash_with_true(array_or_string_or_nil)
        Array(array_or_string_or_nil).to_h { [_1, true] }
      end

      def hint
        get_slot(:hint).presence || default_hint
      end

      def default_hint
        if I18n.exists?("activerecord.attributes.#{object.class.name.underscore}.hints.#{@attribute}")
          I18n.t("activerecord.attributes.#{object.class.name.underscore}.hints.#{@attribute}")
        elsif I18n.exists?("activerecord.attributes.#{object.class.name.underscore}.hints.#{@attribute}_html")
          I18n.t("activerecord.attributes.#{object.class.name.underscore}.hints.#{@attribute}_html").html_safe
        end
      end

      def hint? = hint.present?

      def password?
        false
      end

      def email?
        false
      end

      def autoresize?
        false
      end

      def hintable?
        false
      end
    end
  end
end
