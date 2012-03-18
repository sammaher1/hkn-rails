require 'spec_helper'

describe Admin::TutorController, "when an officer user is logged in" do
  before :each do 
    login_as_officer 
    tutor = mock_model(Tutor, :availabilities => [], :adjacency => 1)
    @current_user.stub(:tutor) { tutor }
  end

  describe "GET 'signup_slots'" do
    before :each do
      @defaults = {wday: 1, hour: 11, preference_level: 0, room_strength: 0, preferred_room: 0}
    end

    it "should be successful" do
      get 'signup_slots'
      response.should be_success
    end

    it "should set @prefs with preference levels" do
      avs = [
        mock_model(Availability, @defaults.merge(wday: 2, hour: 14, preference_level: 2)),
        mock_model(Availability, @defaults.merge(wday: 3, hour: 14, preference_level: 0)),
      ]
      @current_user.tutor.stub(:availabilities) { avs }
      get 'signup_slots'
      assigns(:prefs)[2][14].should eq(2)
      assigns(:prefs)[3][14].should eq(0)
    end

    it "should set @sliders with slider values" do
      avs = [
        mock_model(Availability, @defaults.merge(wday: 2, hour: 14, preferred_room: 0, room_strength: 1)),
        mock_model(Availability, @defaults.merge(wday: 3, hour: 14, preferred_room: 1, room_strength: 2)),
      ]
      @current_user.tutor.stub(:availabilities) { avs }
      get 'signup_slots'
      assigns(:sliders)[2][14].should eq(1)
      assigns(:sliders)[3][14].should eq(4)
    end
  end

  describe "PUT 'update_slots'" do
    it "should be successful" do
      put 'update_slots'
      response.should redirect_to(:admin_tutor_signup_slots)
    end

    describe "Save changes" do
      def update(opts={})
        default_opts = {commit: "Save changes", availabilities: {}}
        put 'update_slots', default_opts.merge(opts)
      end

      before :each do
        tutor = @current_user.tutor
        tutor.stub(:adjacency=)
        tutor.stub(:save!)
      end

      it "sets tutor.adjacency" do
        adjacency = "1"
        @current_user.tutor.should_receive(:adjacency=).with(adjacency)
        update adjacency: adjacency
      end

      it "creates new availabilities" do
        wday = 1
        hour = 11
        pref = 'preferred'
        slider = 3
        avs = {wday => {hour => {preference_level: pref, slider: slider}}}
        Availability.should_receive(:where).and_return([])
        Availability.should_receive(:create!).with(wday: wday, 
          hour: hour, 
          preference_level: Availability::PREF[:preferred], 
          preferred_room: Availability::Room::Soda, 
          room_strength: 1, 
          tutor: @current_user.tutor)
        update availabilities: avs
      end

      it "creates destroy existing availabilities which have been set to unavailable" do
        wday = 1
        hour = 11
        pref = 'unavailable'
        slider = 3
        avs = {wday => {hour => {preference_level: pref, slider: slider}}}
        av = mock_model(Availability)
        Availability.should_receive(:where).and_return([av])
        av.should_receive(:destroy)
        update availabilities: avs
      end

      it "updates existing availabilities" do
        wday = 1
        hour = 11
        pref = 'preferred'
        slider = 3
        avs = {wday => {hour => {preference_level: pref, slider: slider}}}
        av = mock_model(Availability)
        Availability.should_receive(:where).and_return([av])
        av.should_receive(:update_attributes!).with(
          preference_level: Availability::PREF[:preferred], 
          preferred_room: Availability::Room::Soda, 
          room_strength: 1)
        update availabilities: avs
      end
    end

    describe "Reset all" do
      it "should destroy all availabilities for the current person" do
        avs = mock_model("Fake")
        @current_user.tutor.stub(:availabilities) { avs }
        avs.should_receive(:destroy_all)
        put 'update_slots', commit: 'Reset all'
      end
    end
  end

  describe "GET 'signup_courses'" do
    before :each do
      @current_user.tutor.stub(:courses) { [] }
    end

    it "should be successful" do
      get 'signup_courses'
      response.should be_success
    end
  end

  describe "PUT 'update_schedule'" do
      it "redirects non-tutoring officers" do
        put 'update_schedule'
        response.should redirect_to(:root)
      end
  end

  describe "GET 'settings'" do
    it "should be denied" do
      get 'settings'
      response.should_not be_success
    end
  end
end


describe Admin::TutorController, "when a tutoring officer user is logged in" do
  before :each do
    login_as_officer({'tutoring'=>true})
  end

  pending "GET 'generate_schedule'" do
    it "should be successful" do
      get 'generate_schedule'
      response.should be_success
    end
  end

  pending "GET 'view_signups'" do
    it "should be successful" do
      get 'view_signups'
      response.should be_success
    end
  end

  describe "GET 'edit_schedule'" do
    before :each do
      @slots = [
        mock_model(Slot, :wday => 1, :hour => 11, :room => 0, :tutors => [])
      ]
      Slot.stub(:includes).and_return(@slots)
      controller.stub(:compute_stats).and_return(Hash.new({}), Hash.new({}))
    end

    it "should be successful" do
      get 'edit_schedule'
      response.should be_success
    end

    it "grabs all Tutors who are available for a slot" do
      @defaults = {wday: 1, hour: 11, preference_level: 0, room_strength: 0, preferred_room: 0}
      tutor0 = mock_model(Tutor, :adjacency => 1)
      tutor0.stub_chain(:person, :fullname) { "loller"}
      tutor1 = mock_model(Tutor, :adjacency => 1)
      tutor1.stub_chain(:person, :fullname) { "skates"}
      avs = [
        mock_model(Availability, @defaults.merge(preference_level: 2, tutor: tutor0)),
        mock_model(Availability, @defaults.merge(preference_level: 1, tutor: tutor1)),
      ]
      Availability.stub_chain(:current, :includes).and_return avs
      get 'edit_schedule'
      assigns(:slot_options)[0][1][11][:opts][0][1].first.should eq([tutor1.person.fullname + " (pA)", tutor1.id])
      assigns(:slot_options)[0][1][11][:opts][1][1].first.should eq([tutor0.person.fullname + " (pA)", tutor0.id])
    end

    it "grabs all Tutors assigned to a slot even if they are 'unavailable'" do
      all_tutors = [
        mock_model(Tutor, :person => mock_model(Person, :fullname => "Adam")),
        mock_model(Tutor, :person => mock_model(Person, :fullname => "Bert")),
      ]
      all_tutors_output = all_tutors.map{|x| [x.person.fullname, x.id]}
      @slots.first.stub(:tutors).and_return all_tutors
      get 'edit_schedule'
      assigns(:slot_options)[0][1][11][:opts].last[1].should eq(all_tutors_output)
    end

    it "grabs all Tutors when given :all_params" do
      all_tutors = [
        mock_model(Tutor, :person => mock_model(Person, :fullname => "Adam")),
        mock_model(Tutor, :person => mock_model(Person, :fullname => "Bert")),
      ]
      all_tutors_output = all_tutors.map{|x| [x.person.fullname, x.id]}
      Tutor.stub_chain(:current, :includes).and_return all_tutors
      get 'edit_schedule', :all_tutors => true
      assigns(:slot_options)[0][1][11][:opts].last[1].should eq(all_tutors_output)
    end
  end

  describe "compute_stats" do
    it "should work" do
      pending
    end
  end

  describe "PUT 'update_schedule'" do
    def update_schedule(opts={})
      put 'update_schedule', @default_opts.merge(opts)
    end

    before :each do
      @default_opts = {
        only_available: true,
      }
    end

    it "should redirect to edit_schedule" do
      update_schedule
      response.should redirect_to(:admin_tutor_edit_schedule)
    end

    describe "Save changes" do
      before :each do
        s = mock_model(Slot, :wday => 1, :hour => 11, :room => 0, :tutors => mock_model("Fake", :current => []), :tutor_ids => [])
        @slots = [s]
        @new_assignments = []
        assignments = {s.room.to_s => {s.wday.to_s => {s.hour.to_s => @new_assignments}}}
        Slot.stub(:all).and_return(@slots)
        @default_opts.merge!({
          commit: 'Save changes',
          assignments: assignments,
        })
      end

      it "does nothing with no assignments" do
        update_schedule
        #flash[:notice].start_with?(Admin::TutorController::NOTHING_CHANGED).should be_true
        flash[:notice].should eq(Admin::TutorController::NOTHING_CHANGED)
      end

      it "removes tutors which are no longer in a slot" do
        tutor = mock_model(Tutor)
        tutors = mock_model("Fake", :current => [tutor])
        tutors.should_receive(:delete).with(tutor)
        @slots.first.stub(:tutors) { tutors }
        update_schedule
      end

      it "adds tutors which are not already in a slot" do
        tutor0 = mock_model(Tutor)
        tutor1 = mock_model(Tutor)
        tutors = mock_model("Fake", :current => [tutor0, tutor1])
        slot = @slots.first
        slot.stub(:tutor_ids){ [tutor1.id] }
        @new_assignments << tutor0.id << tutor1.id
        Tutor.stub(:find).with(tutor0.id).and_return(tutor0)

        slot.tutors.should_receive(:<<).with tutor0

        update_schedule
      end

      it "does not add tutors which are not already in a slot" do
        tutor0 = mock_model(Tutor)
        tutor1 = mock_model(Tutor)
        tutors = mock_model("Fake", :current => [tutor0, tutor1])
        slot = @slots.first
        slot.stub(:tutor_ids){ [tutor1.id] }
        @new_assignments << tutor0.id << tutor1.id
        Tutor.stub(:find).with(tutor0.id).and_return(tutor0)

        slot.tutors.should_not_receive(:<<).with tutor1

        update_schedule
      end
    end

    describe "Reset all" do
      before :each do
        @default_opts.merge!({
          commit: 'Reset all',
        })
      end

      it "clears tutoring assignments" do
        tutors = mock_model("Fake")
        slots = [
          mock_model(Slot, :tutors => tutors),
          mock_model(Slot, :tutors => tutors),
          mock_model(Slot, :tutors => tutors),
        ]
        tutors.should_receive(:clear).exactly(3).times
        Slot.stub(:all) { slots }
        update_schedule
      end
    end
  end

  describe "GET 'settings'" do
    it "should be successful" do
      get 'settings'
      response.should be_success
    end
  end
end

describe Admin::TutorController, "when no user is logged in" do
  it "should redirect to the login page" do
    get 'settings'
    response.should redirect_to(:login)
  end
end
