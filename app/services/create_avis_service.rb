# frozen_string_literal: true

class CreateAvisService
  Result = Struct.new(:avis, :sent_emails, :failed_avis)

  def self.call(dossier:, instructeur_or_expert:, params:)
    new(dossier, instructeur_or_expert, params).call
  end

  def initialize(dossier, instructeur_or_expert, params)
    @dossier = dossier
    @instructeur_or_expert = instructeur_or_expert
    @params = params
  end

  def call
    if @params[:emails].blank? || @params[:emails].all?(&:blank?)
      avis = Avis.new(@params)
      avis.errors.add(:emails, :blank)
      return Result.new(avis, [], [avis])
    end

    confidentiel = @params[:confidentiel] || false
    emails = Array(@params[:emails]).map(&:strip).map(&:downcase).reject(&:blank?)
    allowed_dossiers = [@dossier]

    if @params[:invite_linked_dossiers].present?
      allowed_dossiers += @dossier.linked_dossiers_for(@instructeur_or_expert)
    end

    if @instructeur_or_expert.is_a?(Instructeur) &&
        !@instructeur_or_expert.follows.exists?(dossier: @dossier)
      @instructeur_or_expert.follow(@dossier)
    end

    sent_emails = []
    create_results = Avis.create(
      emails.flat_map do |email|
        user = User.create_or_promote_to_expert(email, SecureRandom.hex)
        allowed_dossiers.map do |dossier|
          experts_procedure = user.valid? ? ExpertsProcedure.find_or_create_by(procedure: dossier.procedure, expert: user.expert) : nil

          {
            email: email,
            introduction: @params[:introduction],
            introduction_file: @params[:introduction_file],
            claimant: @instructeur_or_expert,
            dossier: dossier,
            confidentiel: confidentiel,
            experts_procedure: experts_procedure,
            question_label: @params[:question_label]
          }
        end
      end
    )

    @dossier.avis.reload
    persisted, failed = create_results.partition(&:persisted?)

    persisted.each do |avis|
      avis.dossier.demander_un_avis!(avis)
      if avis.dossier == @dossier
        if avis.experts_procedure.notify_on_new_avis?
          if avis.expert.user.unverified_email?
            avis.expert.user.invite_expert_and_send_avis!(avis)
          else
            AvisMailer.avis_invitation(avis).deliver_later
          end
        end
        sent_emails << avis.expert.email
        avis.update_column(:email, nil)
      end
    end

    if persisted.any?
      Result.new(persisted.first, sent_emails.uniq, [])
    else
      avis_with_errors = Avis.new(@params.merge(emails: failed.map(&:email).uniq))
      avis_with_errors.errors.merge!(failed.first.errors)
      Result.new(avis_with_errors, [], failed)
    end
  end
end
