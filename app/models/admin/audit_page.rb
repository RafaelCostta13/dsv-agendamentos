module Admin
  class AuditPage
    SIZE = 25
    attr_reader :events, :page, :total_pages, :total_count, :bookings, :users

    def initialize(scope:, page:, chronological: false)
      @total_count = scope.count
      @total_pages = [ (@total_count.to_f/SIZE).ceil, 1 ].max
      number = page.to_s.match?(/\A[0-9]{1,9}\z/) ? page.to_i : 1
      @page = number.clamp(1, @total_pages)
      direction = chronological ? :asc : :desc
      @events = scope.order(created_at: direction, id: direction).limit(SIZE).offset((@page-1)*SIZE).to_a
      ids = @events.select { |event| event.entity_type == "Booking" }.map(&:entity_id).uniq
      @bookings = Booking.where(id: ids).select(:id, :protocol).index_by(&:id)
      user_ids = @events.select { |event| event.entity_type == "User" }.map(&:entity_id).uniq
      @users = User.where(id: user_ids).select(:id, :name, :email).index_by(&:id)
    end
  end
end
