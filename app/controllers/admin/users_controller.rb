module Admin
  class UsersController < BaseController
    PAGE_SIZE = 25
    before_action :prepare_filters
    rescue_from ActiveRecord::RecordNotFound, with: :user_not_found

    def index
      totals = User.group(:active).count
      @totals = { total: totals.values.sum, active: totals.fetch(true, 0), inactive: totals.fetch(false, 0) }
      scope = @user_filters.scope
      @total_count = scope.count
      @total_pages = [ (@total_count.to_f/PAGE_SIZE).ceil, 1 ].max
      number = params[:page].to_s.match?(/\A[0-9]{1,9}\z/) ? params[:page].to_i : 1
      @page = number.clamp(1, @total_pages)
      @users = scope.select(:id, :name, :email, :role, :active, :created_at).order(:name, :id).limit(PAGE_SIZE).offset((@page-1)*PAGE_SIZE)
    end

    def new
      @user = User.new(role: "operator", active: true)
    end

    def show
      load_user
    end

    def edit
      load_user
    end

    def create
      run_operation("create", creation_params)
      if @operation_succeeded
        redirect_to admin_user_path(@user), status: :see_other, notice: "Usuário cadastrado com sucesso."
      else
        @user ||= User.new(creation_params.except(:password, :password_confirmation))
        render :new, status: @operation.http_status
      end
    end

    def update
      load_user
      values = params.require(:user).permit(:name, :email, :lock_version)
      values[:role] = submitted_role if params.require(:user).key?(:role)
      if values.key?(:role) && @user.role != values[:role] && params[:intent] != "confirm_role"
        @previous_role = @user.role
        @user.assign_attributes(values.except(:lock_version))
        if @user.valid? && values[:lock_version].to_s == @user.lock_version.to_s
          @submitted_version = values[:lock_version]
          return render :confirm_role
        end
        @user.errors.add(:base, ManageUser::VERSION_MESSAGE) if values[:lock_version].to_s != @user.lock_version.to_s
        @submitted_version = values[:lock_version]
        return render :edit, status: values[:lock_version].to_s != @user.lock_version.to_s ? :conflict : :unprocessable_entity
      end
      run_operation("update", values.except(:lock_version), version: values[:lock_version])
      if @operation_succeeded
        redirect_to admin_user_path(@user), status: :see_other, notice: "Usuário atualizado com sucesso."
      else
        @submitted_version = values[:lock_version]
        render :edit, status: @operation.http_status
      end
    end

    def activation
      load_user
      @command = "activate"
      render :state_confirmation
    end

    def deactivation
      load_user
      @command = "deactivate"
      render :state_confirmation
    end

    def activate
      state_operation("activate")
    end

    def deactivate
      state_operation("deactivate")
    end

    def password_reset
      load_user
    end

    def reset_password
      load_user
      values = params.require(:user).permit(:password, :password_confirmation, :lock_version, :reason)
      run_operation("password_reset", values.slice(:password, :password_confirmation), version: values[:lock_version], reason: values[:reason])
      if @operation_succeeded
        redirect_to admin_user_path(@user), status: :see_other, notice: "Senha redefinida com sucesso."
      else
        @submitted_version = values[:lock_version]
        @reason = values[:reason]
        render :password_reset, status: @operation.http_status
      end
    end

    private

    def prepare_filters
      filters.valid?
      @user_filters = UserFilters.new(params.permit(:q, :role, :state).to_h)
      @user_filters.valid?
    end

    def load_user
      @user = User.find(params[:id])
    end

    def creation_params
      values = params.require(:user).permit(:name, :email, :active, :password, :password_confirmation).to_h.symbolize_keys
      values.merge(role: submitted_role)
    end

    def submitted_role
      # Roles are deliberately managed here; accept only the fixed server-side list.
      value = params.require(:user)[:role]
      User::ROLES.key?(value) ? value : nil
    end

    def run_operation(command, values, version: nil, reason: nil)
      @operation = ManageUser.new(action: command, user_id: params[:id], attributes: values.to_h, lock_version: version, reason: reason, actor: current_user)
      success = @operation_succeeded = @operation.call
      @user = @operation.user || @user
      success
    end

    def state_operation(command)
      load_user
      values = params.require(:user).permit(:lock_version, :reason)
      run_operation(command, {}, version: values[:lock_version], reason: values[:reason])
      if @operation_succeeded
        redirect_to admin_user_path(@user), status: :see_other, notice: command == "activate" ? "Usuário ativado com sucesso." : "Usuário desativado com sucesso."
      else
        @command, @reason, @submitted_version = command, values[:reason], values[:lock_version]
        render :state_confirmation, status: @operation.http_status
      end
    end

    def user_not_found
      render_query_error("Usuário não encontrado", "A conta solicitada não foi encontrada.", :not_found)
    end
  end
end
