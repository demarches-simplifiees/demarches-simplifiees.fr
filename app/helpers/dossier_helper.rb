# frozen_string_literal: true

module DossierHelper
  include EtablissementHelper

  def button_or_label_class(dossier)
    if dossier.accepte?
      'accepted'
    elsif dossier.sans_suite?
      'without-continuation'
    elsif dossier.refuse?
      'refused'
    end
  end

  def highlight_if_unseen_class(seen_at, updated_at)
    if updated_at.present? && seen_at&.<(updated_at)
      "highlighted"
    end
  end

  def url_for_dossier(dossier)
    if dossier.brouillon?
      brouillon_dossier_path(dossier)
    else
      dossier_path(dossier)
    end
  end

  def url_for_new_dossier(revision)
    new_dossier_url(procedure_id: revision.procedure.id, brouillon: revision.draft? ? true : nil)
  end

  def commencer_dossier_vide_for_revision_path(revision)
    revision.draft? ? commencer_dossier_vide_test_path(path: revision.procedure.path) : commencer_dossier_vide_path(path: revision.procedure.path)
  end

  def dossier_submission_is_closed?(dossier)
    return false if dossier.editing_fork?
    dossier.brouillon? && dossier.procedure.close?
  end

  def dossier_display_state(dossier_or_state, lower: false)
    state = dossier_or_state.is_a?(Dossier) ? dossier_or_state.state : dossier_or_state
    display_state = Dossier.human_attribute_name("state.#{state}")
    lower ? display_state.downcase : display_state
  end

  def dossier_legacy_state(dossier)
    case dossier.state
    when Dossier.states.fetch(:en_construction)
      'initiated'
    when Dossier.states.fetch(:en_instruction)
      'received'
    when Dossier.states.fetch(:accepte)
      'closed'
    when Dossier.states.fetch(:refuse)
      'refused'
    when Dossier.states.fetch(:sans_suite)
      'without_continuation'
    else
      dossier.state
    end
  end

  def class_badge_state(state)
    case state
    when Dossier.states.fetch(:en_construction)
      'fr-badge--purple-glycine'
    when Dossier.states.fetch(:en_instruction)
      'fr-badge--new'
    when Dossier.states.fetch(:accepte)
      'fr-badge--success'
    when Dossier.states.fetch(:refuse), Dossier.states.fetch(:sans_suite)
      'fr-badge--warning'
    when Dossier.states.fetch(:brouillon)
      ''
    else
      ''
    end
  end

  def status_badge_user(dossier, alignment_class = '')
    if dossier.hide_info_with_accuse_lecture?
      tag.span 'traité', role: 'status', class: "fr-badge fr-badge--sm fr-badge--no-icon #{alignment_class}"
    else
      status_badge(dossier.state, alignment_class)
    end
  end

  def status_badge(state, alignment_class = '')
    status_text = dossier_display_state(state, lower: true)
    tag.span status_text, role: 'status', class: class_names(
      'fr-badge fr-badge--sm' => true,
      'fr-badge--no-icon' => Dossier.states.fetch(:accepte).exclude?(state),
      class_badge_state(state) => true,
      alignment_class => true
    )
  end

  def deletion_reason_badge(reason)
    if reason.present?
      status_text = I18n.t(reason, scope: 'activerecord.attributes.deleted_dossier.reason')
      status_class = reason.tr('_', '-')
    else
      status_text = I18n.t('activerecord.attributes.deleted_dossier.reason.unknown')
      status_class = 'unknown'
    end

    tag.span(status_text, class: "fr-badge #{status_class} ")
  end

  def pending_correction_badge(profile, html_class: nil)
    tag.span(Dossier.human_attribute_name("pending_correction.#{profile}"), class:
      class_names(
        "fr-badge fr-badge--sm",
        "fr-badge--warning super" => profile == :for_user,
        html_class => true
      ), role: 'status')
  end

  def correction_resolved_badge(html_class: nil)
    tag.span(Dossier.human_attribute_name("pending_correction.resolved"), class: ['fr-badge fr-badge--sm fr-badge--success', html_class], role: 'status')
  end

  def tags_label(labels)
    if labels.size > 1
      tag.ul(class: 'fr-tags-group') do
        safe_join(labels.map { |l| tag.li(tag_label(l.name, l.color)) })
      end
    elsif labels.one?
      label = labels.first
      tag_label(label.name, label.color)
    end
  end

  def tag_label(name, color)
    tag.span(name, class: "fr-tag fr-tag--sm fr-tag--#{Label.class_name(color)} no-wrap")
  end

  def tag_summary_notification(notification_type_count)
    type, count = notification_type_count

    tag.span(class: [badge_notification_class(type), 'fr-badge--no-icon']) do
      safe_join([
        tag.span(count, class: "fr-background-alt--grey fr-my-1v fr-mr-1v fr-px-1v fr-text-default--grey"),
        tag.span(nil, class: [badge_notification_class(type), 'fr-my-0', 'fr-mx-0', 'fr-px-0'], aria: { hidden: true }),
        badge_notification_text(type, generic: true)
      ])
    end
  end

  def tags_summary_notification(notifications_counts_by_type)
    tag.ul(class: 'fr-badge-group fr-mt-2w') do
      safe_join(notifications_counts_by_type.map { |notif| tag.li(tag_summary_notification(notif)) })
    end
  end

  def tag_notification(notification, generic: false)
    tag.span(badge_notification_text(notification, generic:), class: badge_notification_class(notification))
  end

  def tags_notification(notifications, generic: false)
    tag.ul(class: 'fr-badge-group') do
      safe_join(notifications.map { |notif| tag.li(tag_notification(notif, generic:)) })
    end
  end

  def badge_notification_class(notification)
    type = extract_notification_type(notification)

    case type
    when DossierNotification.notification_types.fetch(:dossier_depose)
      "fr-badge fr-badge--sm fr-badge--warning"
    when DossierNotification.notification_types.fetch(:dossier_modifie),
      DossierNotification.notification_types.fetch(:message_usager),
      DossierNotification.notification_types.fetch(:annotation_instructeur),
      DossierNotification.notification_types.fetch(:avis_externe)
      "fr-badge fr-badge--sm fr-badge--new"
    when DossierNotification.notification_types.fetch(:attente_correction),
      DossierNotification.notification_types.fetch(:attente_avis)
      "fr-badge fr-badge--sm"
    end
  end

  def badge_notification_text(notification, generic)
    type = extract_notification_type(notification)

    case type
    when DossierNotification.notification_types.fetch(:dossier_depose)
      if generic[:generic]
        t("activerecord.attributes.notification.#{type}.generic")
      else
        t("activerecord.attributes.notification.#{type}.specific", days: (Time.current.to_date - notification.display_at.to_date).to_i)
      end
    else
      t("activerecord.attributes.notification.#{type}")
    end
  end

  def demandeur_dossier(dossier)
    if dossier.procedure.for_individual? && dossier.for_tiers?
      return t('shared.dossiers.beneficiaire', mandataire: dossier.mandataire_full_name, beneficiaire: "#{dossier&.individual&.prenom} #{dossier&.individual&.nom}")
    end

    if dossier.procedure.for_individual?
      return "#{dossier&.individual&.nom} #{dossier&.individual&.prenom}"
    end

    return "" if dossier.etablissement.blank?

    if dossier.etablissement.diffusable_commercialement == false
      "SIRET #{pretty_siret(dossier.etablissement.siret)}"
    else
      raison_sociale_or_name(dossier.etablissement)
    end
  end

  def safe_expiration_date(dossier)
    l(dossier.expiration_date, format: '%d/%m/%Y')
  end

  def annuaire_link(siren_or_siret = nil)
    base_url = "https://annuaire-entreprises.data.gouv.fr"
    return base_url if siren_or_siret.blank?
    "#{base_url}/rechercher?terme=#{siren_or_siret}"
  end

  def france_connect_informations(user_information)
    if user_information.full_name.empty?
      t("shared.dossiers.france_connect_informations.details_no_name")
    elsif user_information.updated_at.present?
      t("shared.dossiers.france_connect_informations.details_updated",
          name: user_information.full_name,
          date: l(user_information.updated_at.to_date, format: :default))
    else
      t("shared.dossiers.france_connect_informations.details", name: user_information.full_name)
    end
  end

  private

  def extract_notification_type(notification_or_type)
    notification_or_type.is_a?(DossierNotification) ? notification_or_type.notification_type : notification_or_type
  end
end
