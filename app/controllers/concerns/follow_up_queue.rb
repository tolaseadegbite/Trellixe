module FollowUpQueue
  extend ActiveSupport::Concern

  # Everything a queue reader needs. `records` is the filtered relation so
  # callers can paginate the footer from the identical scope.
  QueueState = Struct.new(:current, :up_next, :total, :overdue, :records,
                          :position, :prev_id, keyword_init: true)

  class << self
    def records_for(user, account, q_params)
      user.follow_up_tasks.for_account(account).pending
          .ransack(q_params).result
          .includes(invitation: [ :contact, :event ], interaction_logs: :user)
          .order(due_at: :asc)
    end

    # Sequential work queue: the current card plus up to 3 next, with
    # filtered totals for the progress header. Focus (from ?focus=) picks
    # which task is current; anything else falls back to first-due.
    def load_for(user, account, q_params, focus_id = nil)
      records = records_for(user, account, q_params)
      ids = records.pluck(:id)
      index = focus_id && ids.include?(focus_id.to_i) ? ids.index(focus_id.to_i) : 0
      window = ids[index, 4] || []
      tasks = records.where(id: window).index_by(&:id).values_at(*window).compact

      QueueState.new(
        current: tasks.first,
        up_next: tasks[1, 3] || [],
        total: ids.size,
        overdue: records.where("follow_up_tasks.due_at < ?", Time.current).count,
        records: records,
        position: tasks.any? ? index + 1 : 0,
        prev_id: index.positive? ? ids[index - 1] : nil
      )
    end

    # Scope + filters echoed into queue form actions and links so advances
    # preserve the user's view. Never includes focus (actions reset to first).
    def context_for(request_params, scope)
      { scope: scope }.tap do |ctx|
        ctx[:q] = request_params[:q].to_unsafe_h if request_params[:q].present?
      end
    end
  end

  private

  # Request-state shortcut for the including controller.
  def queue_state(focus_id = nil, q_params = params[:q])
    FollowUpQueue.load_for(current_user, Current.account, q_params, focus_id)
  end
end
