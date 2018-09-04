require 'test_helper'

class ActivitiesTest < ActionDispatch::IntegrationTest
  
  def setup
    @user = users(:john)
    @rooms = Room.all
    log_in_as(@user)
  end

  test "borrow room without logged in" do
    session.delete(:user_id)
    assert_no_difference 'Activity.count' do
      post activities_path, params: { activity: { room_id: @rooms[0].id,
                                                  action:  'borrowing' } }
    end
    assert_redirected_to new_session_path
    assert_not flash[:danger].empty?
  end

  test "borrow room" do
    get root_path
    assert_select 'form[action=?]', activities_path
    assert_select 'input[type=hidden][action=borrowing]', count: @rooms.count
    assert_select 'input[type=hidden][action=returning]', count: 0
    assert_difference 'Activity.count', 1 do
      post activities_path, params: { activity: { room_id: @rooms[0].id,
                                                  action:  'borrowing' } }
    end
    assert_redirected_to root_path
    assert_not flash[:success].empty?
    follow_redirect!
    assert_select 'input[type=hidden][action=borrowing]', count: @rooms.count - 1
    assert_select 'input[type=hidden][action=returning]', count: 1
  end

  test "return room" do
    get root_path
    # borrow
    post activities_path, params: { activity: { room_id: @rooms[0].id,
                                                action:  'borrowing' } }
    # return
    assert_difference 'Activity.count', 1 do # not `-1`
      post activities_path, params: { activity: { room_id: @rooms[0].id,
                                                  action:  'returning' } }
    end

    assert_redirected_to root_path
    assert_not flash[:success].empty?
    follow_redirect!
    assert_select 'input[type=hidden][action=borrowing]', count: @rooms.count
    assert_select 'input[type=hidden][action=returning]', count: 0                            
  end

  test "should not return room already returned" do
    get root_path
    assert_no_difference 'Activity.count' do
      post activities_path, params: { activity: { room_id: @rooms[0].id,
                                                  action:  'returning' } }
    end
    assert_redirected_to root_path
    assert_not flash[:danger].empty?
  end

  test "should not borrow room already borrowed" do
    get root_path

    # borrow
    post activities_path, params: { activity: { room_id: @rooms[0].id,
                                                action:  'borrowing' } }


    # borrow again
    assert_no_difference 'Activity.count' do
      post activities_path, params: { activity: { room_id: @rooms[0].id,
                                                  action:  'borrowing' } }
    end

    assert_redirected_to root_path
    assert_not flash[:danger].empty?
  end

  test "destroy activity" do
    get root_path

    # borrow
    post activities_path, params: { activity: { room_id: @rooms[0].id,
                                                action:  'borrowing' } }

    # cancel borrow
    assert_difference 'Activity.count', -1 do
      delete activity_path(Activity.first)
    end

    assert_redirected_to root_path
    assert_not flash[:success].empty?
  end
end
