module Admin
  class AuditEventsController < BaseController
    rescue_from ActiveRecord::RecordNotFound, with: :event_not_found

    def index
      filters.valid?
      @audit_filters = AuditFilters.new(params.permit(:start_date, :end_date, :event, :entity_type, :booking_protocol, :actor_user_id).to_h)
      @audit_page = AuditPage.new(scope: permitted_audit_scope(@audit_filters.scope), page: params[:page])
      @audit_actors = User.where(id: permitted_audit_scope(AuditEvent.all).where.not(actor_user_id: nil).select(:actor_user_id)).order(:name).select(:id, :name).limit(500)
    end

    def show
      filters.valid?
      id = params[:id].to_s
      unless id.match?(/\A[1-9][0-9]{0,18}\z/) && id.to_i <= 9_223_372_036_854_775_807
        raise ActiveRecord::RecordNotFound
      end
      @event = AuditEvent.find(params[:id])
      return render("admin/shared/forbidden", status: :forbidden) if restricted_event?(@event)
      @reference_booking = Booking.select(:id, :protocol).find_by(id: @event.entity_id) if @event.entity_type == "Booking"
      @reference_user = User.select(:id, :name, :email).find_by(id: @event.entity_id) if @event.entity_type == "User"
      @audit_filters = AuditFilters.new(params.permit(:start_date, :end_date, :event, :entity_type, :booking_protocol, :actor_user_id).to_h)
      @audit_filters.valid?
    end

    private

    def permitted_audit_scope(scope)
      current_user.role == "admin" ? scope : scope.where.not(entity_type: "User")
    end

    def restricted_event?(event)
      current_user.role != "admin" && event.entity_type == "User"
    end

    def event_not_found
      render_query_error("Evento não encontrado", "O evento solicitado não foi encontrado.", :not_found)
    end
  end
end
