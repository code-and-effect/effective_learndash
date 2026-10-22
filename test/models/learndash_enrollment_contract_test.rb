require 'test_helper'
require 'minitest/mock'

class LearndashEnrollmentContractTest < ActiveSupport::TestCase
  setup do
    @enrollment = Effective::LearndashEnrollment.new
  end

  test 'LearnDash 5 statuses retain the existing persisted vocabulary and predicates' do
    assign(progress_status: 'not_started')
    assert_equal 'not-started', @enrollment.progress_status
    assert @enrollment.not_started?

    assign(progress_status: 'in_progress')
    assert_equal 'in-progress', @enrollment.progress_status
    assert @enrollment.in_progress?

    assign(progress_status: 'completed')
    assert @enrollment.completed?
  end

  test 'LearnDash 4 statuses and missing statuses remain supported' do
    assign(progress_status: 'not-started')
    assert @enrollment.not_started?
    assign(progress_status: 'in-progress')
    assert @enrollment.in_progress?
    assign(progress_status: nil)
    assert_nil @enrollment.progress_status
  end

  test 'GMT dates take precedence over LearnDash 5 site-local dates' do
    Time.use_zone('America/Edmonton') do
      assign(progress_status: 'completed',
        date_started: '2026-10-20T09:00:00', date_started_gmt: '2026-10-20T15:00:00',
        date_completed: '2026-10-21T10:30:00', date_completed_gmt: '2026-10-21T16:30:00')

      assert_equal Time.utc(2026, 10, 20, 15), @enrollment.date_started
      assert_equal Time.utc(2026, 10, 21, 16, 30), @enrollment.date_completed
    end
  end

  test 'legacy responses without GMT fields keep UTC date interpretation' do
    Time.use_zone('America/Edmonton') do
      assign(progress_status: 'completed', date_started: '2026-10-20T15:00:00', date_completed: '2026-10-21T16:30:00')
      assert_equal Time.utc(2026, 10, 20, 15), @enrollment.date_started
      assert_equal Time.utc(2026, 10, 21, 16, 30), @enrollment.date_completed
    end
  end

  test 'explicitly blank GMT dates do not import site-local values as UTC' do
    assign(progress_status: 'not_started',
      date_started_gmt: '', date_started: '2026-10-20T09:00:00',
      date_completed_gmt: nil, date_completed: '2026-10-21T10:30:00')

    assert_nil @enrollment.date_started
    assert_nil @enrollment.date_completed
  end

  test 'completed and admin-completed enrollments are not downgraded' do
    @enrollment.progress_status = 'completed'
    assign(progress_status: 'in_progress')
    assert_equal 'completed', @enrollment.progress_status

    @enrollment.assign_attributes(progress_status: nil, admin_completed: true)
    assign(progress_status: 'not_started')
    assert @enrollment.completed?
    assert_nil @enrollment.progress_status
  end

  test 'step counts and last step continue to synchronize with LearnDash 5 data' do
    assign(progress_status: 'in_progress', last_step: 99, steps_completed: 4, steps_total: 12)
    assert_equal 99, @enrollment.last_step
    assert_equal 4, @enrollment.steps_completed
    assert_equal 12, @enrollment.steps_total
    assert @enrollment.last_synced_at.present?
  end

  private

  def assign(data)
    EffectiveLearndash.stub(:disabled?, false) { @enrollment.assign_api_attributes(data) }
  end
end
