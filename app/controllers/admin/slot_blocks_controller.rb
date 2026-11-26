module Admin
  class SlotBlocksController < BaseController
    PAGE_SIZE = 25
    before_action :prepare_filters
    rescue_from ActiveRecord::RecordNotFound, with: :block_not_found

    def index
      initialize_selection
      load_list
    end

    def create
      values = params.require(:slot_block).permit(:blocked_date, :reason, dock_numbers: [], slot_numbers: []).to_h
      values["blocked_date"] = params.permit(:selected_date)[:selected_date] if params.key?(:selected_date)
      @selection = BlockSelection.new(values)
      if params.key?(:selected_date) || params[:selection_command].present?
        update_selection
        load_list
        render :index
      else
        @block_operation = BlockSlots.new(@selection, actor: current_user)
        if params[:intent] == "review"
          if @block_operation.preview
            render :confirm_block
          else
            load_list
            render :index, status: @block_operation.http_status
          end
        elsif @block_operation.call
          redirect_to admin_slot_blocks_path(date: @selection.blocked_date.iso8601), status: :see_other, notice: @block_operation.notice
        else
          load_list
          render :index, status: @block_operation.http_status
        end
      end
    end

    def unblocking
      block = SlotBlock.find(params[:id])
      @single_id = block.id
      @unblock_operation = UnblockSlots.new(tokens: [ block.unlock_token ], expected_id: block.id.to_s, actor: current_user)
      if @unblock_operation.preview
        render :confirm_unblock
      else
        initialize_selection
        load_list
        render :index, status: @unblock_operation.http_status
      end
    end

    def review_unblock
      if %w[select_page clear_page].include?(params[:intent])
        initialize_selection
        load_list
        @selected_ids = params[:intent] == "select_page" ? @blocks.select(&:unblock_eligible?).map(&:id) : []
        render :index
        return
      end
      @unblock_operation = UnblockSlots.new(tokens: params.permit(block_tokens: [])[:block_tokens], actor: current_user)
      if @unblock_operation.preview
        render :confirm_unblock
      else
        initialize_selection
        load_list
        render :index, status: @unblock_operation.http_status
      end
    end

    def destroy
      @single_id = params[:id]
      perform_unblock(expected_id: @single_id)
    end

    def bulk_unblock
      perform_unblock
    end

    private

    def initialize_selection
      filters.valid?
      date = AgendaDefinition.permitted_date?(selected_date) ? selected_date : Date.current
      @selection ||= BlockSelection.new(blocked_date: date)
    end

    def prepare_filters
      filters.valid?
    end

    def filters
      @filters ||= BookingFilters.new(params.permit(:date, :dock_number).to_h)
    end

    def load_list
      filters.valid?
      @dates = (Date.current..Date.current + 2).to_a
      scope = filters.errors.any? ? SlotBlock.none : SlotBlock.all
      scope = scope.where(blocked_date: filters.parsed_date) if filters.date.present?
      scope = scope.where(dock_number: filters.dock_number) if filters.dock_number.present?
      @total_count = scope.count
      @total_pages = [ (@total_count.to_f / PAGE_SIZE).ceil, 1 ].max
      requested = params[:page].to_s.match?(/\A[0-9]{1,9}\z/) ? params[:page].to_i : 1
      @page = requested.clamp(1, @total_pages)
      @blocks = scope.order(:blocked_date, :dock_number, :slot_number, :id).limit(PAGE_SIZE).offset((@page - 1) * PAGE_SIZE).to_a
      @selected_ids ||= []
    end

    def update_selection
      filters.valid?
      case params[:selection_command]
      when "all_docks" then @selection.dock_numbers = AgendaDefinition::DOCK_NUMBERS.to_a
      when "clear_docks" then @selection.dock_numbers = []
      when "all_slots" then @selection.slot_numbers = @selection.eligible_slots
      when "clear_slots" then @selection.slot_numbers = []
      when "back" then nil
      when nil, "" then @selection.slot_numbers &= @selection.eligible_slots
      else @selection.errors.add(:base, "Seleção inválida.")
      end
    end

    def perform_unblock(expected_id: nil)
      @unblock_operation = UnblockSlots.new(tokens: params.permit(block_tokens: [])[:block_tokens], expected_id: expected_id, actor: current_user)
      if @unblock_operation.call
        notice = "#{@unblock_operation.removed_count} posições desbloqueadas com sucesso. As demais regras de disponibilidade continuam válidas."
        notice += " #{@unblock_operation.reserved_count} posições permanecem ocupadas por agendamentos." if @unblock_operation.reserved_count.positive?
        redirect_to admin_slot_blocks_path(admin_context), status: :see_other, notice: notice
      else
        initialize_selection
        load_list
        render :index, status: @unblock_operation.http_status
      end
    end

    def block_not_found
      render_query_error("Bloqueio não encontrado", "O bloqueio solicitado não foi encontrado.", :not_found)
    end
  end
end
