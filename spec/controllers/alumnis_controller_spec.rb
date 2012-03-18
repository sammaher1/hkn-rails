require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by the Rails when you ran the scaffold generator.

describe AlumnisController do
  before :each do login_as_officer('alumrel'=>true) end
  
  def mock_alumni(stubs={})
    @mock_alumni ||= mock_model(Alumni, stubs).as_null_object
  end

  describe "GET index" do
    it "assigns all alumnis as @alumnis" do
      Alumni.stub(:all) { [mock_alumni] }
      get :index
      assigns(:alumnis).should eq([mock_alumni])
    end
  end

  describe "GET show" do
    it "assigns the requested alumni as @alumni" do
      Alumni.stub(:find).with("37") { mock_alumni }
      get :show, :id => "37"
      assigns(:alumni).should be(mock_alumni)
    end
  end

  describe "GET new" do
    it "assigns a new alumni as @alumni" do
      Alumni.stub(:new) { mock_alumni }
      get :new
      assigns(:alumni).should be(mock_alumni)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "assigns a newly created alumni as @alumni" do
        Alumni.stub(:new).with({'these' => 'params'}) { mock_alumni(:save => true) }
        post :create, :alumni => {'these' => 'params'}
        assigns(:alumni).should be(mock_alumni)
      end

      it "redirects to the created alumni" do
        Alumni.stub(:new) { mock_alumni(:save => true) }
        Alumni.stub(:find).and_return(mock_alumni)
        @current_user.stub(:save).and_return true
        post :create, :alumni => {}

        response.should redirect_to(alumni_url(mock_alumni))
      end
    end

    describe "with invalid params" do
      before :each do
        @current_user.stub(:alumni=)
      end

      it "assigns a newly created but unsaved alumni as @alumni" do
        Alumni.stub(:new).with({'these' => 'params'}) { mock_alumni(:save => false) }
        post :create, :alumni => {'these' => 'params'}
        assigns(:alumni).should be(mock_alumni)
      end

      it "re-renders the 'new' template" do
        Alumni.stub(:new) { mock_alumni(:save => false) }
        post :create, :alumni => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested alumni" do
        Alumni.stub(:find).with(:first, {:conditions=>"\"alumnis\".person_id = 1052"}) { mock_alumni }
        Alumni.stub(:find).with("37") { mock_alumni }
        mock_alumni.should_receive(:update_attributes).with({'these' => 'params'})
        
        put :update, :id => "37", :alumni => {'these' => 'params'}
      end

      it "assigns the requested alumni as @alumni" do
        Alumni.stub(:find) { mock_alumni(:update_attributes => true) }
        put :update, :id => "1"
        assigns(:alumni).should be(mock_alumni)
      end

      it "redirects to the alumni" do
        Alumni.stub(:find) { mock_alumni(:update_attributes => true) }
        put :update, :id => "1"
        response.should redirect_to(alumni_url(mock_alumni))
      end
    end

    describe "with invalid params" do
      it "assigns the alumni as @alumni" do
        Alumni.stub(:find) { mock_alumni(:update_attributes => false) }
        put :update, :id => "1"
        assigns(:alumni).should be(mock_alumni)
      end

      it "re-renders the 'edit' template" do
        Alumni.stub(:find) { mock_alumni(:update_attributes => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested alumni" do
      Alumni.stub(:find).with("37") { mock_alumni }
      mock_alumni.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the alumnis list" do
      Alumni.stub(:find) { mock_alumni }
      delete :destroy, :id => "1"
      response.should redirect_to(alumnis_url)
    end
  end

end
