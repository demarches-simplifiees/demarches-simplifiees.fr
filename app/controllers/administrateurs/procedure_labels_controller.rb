# frozen_string_literal: true

module Administrateurs
  class ProcedureLabelsController < AdministrateurController
    before_action :retrieve_procedure
    before_action :retrieve_label, only: [:edit, :update, :destroy]
    before_action :set_colors_collection, only: [:edit, :new, :create, :update]

    def index
      @labels = @procedure.procedure_labels
    end

    def edit
    end

    def new
      @label = ProcedureLabel.new
    end

    def create
      @label = @procedure.procedure_labels.build(procedure_label_params)

      if @label.save
        flash.notice = 'Le label a bien été créé'
        redirect_to [:admin, @procedure, :procedure_labels]
      else
        flash.alert = @label.errors.full_messages
        render :new
      end
    end

    def update
      if @label.update(procedure_label_params)
        flash.notice = 'Le label a bien été modifié'
        redirect_to [:admin, @procedure, :procedure_labels]
      else
        flash.alert = @label.errors.full_messages
        render :edit
      end
    end

    def destroy
      @label.destroy!
      flash.notice = 'Le label a bien été supprimé'
      redirect_to [:admin, @procedure, :procedure_labels]
    end

    private

    def procedure_label_params
      params.require(:procedure_label).permit(:name, :color)
    end

    def retrieve_label
      @label = @procedure.procedure_labels.find(params[:id])
    end

    def set_colors_collection
      @colors_collection = ProcedureLabel.colors.values
    end
  end
end
