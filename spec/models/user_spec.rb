require 'spec_helper'

describe User do
  before(:each) do 
    orgs_response = mock(OAuth2::Response)
    users_response = mock(OAuth2::Response)
    @access_token = mock(OAuth2::AccessToken)

    @access_token.stub(:get).with('/api/organizations').and_return(orgs_response)
    orgs_response.stub(:parsed).and_return([{"id" => 1, "name" => "CSOOrganization"}, {"id" => 2, "name" => "Ashoka"}])

    @access_token.stub(:get).with('/api/organizations/1/users').and_return(users_response)
    users_response.stub(:parsed).and_return([{"id" => 1, "name" => "Bob"}, {"id" => 2, "name" => "John"}])
  end

  it "returns the list of users of an organizations" do
    users = User.find_by_organization(@access_token, 1)
    users.map(&:id).should include 1
    users.map(&:name).should include "Bob"
  end

  it "creates a user object from json" do
    user = User.json_to_user({"id" => 1, "name" => "John"})
    user.class.should eq User
    user.id.should eq 1
    user.name.should eq "John"
  end
end

