require 'spec_helper'

describe Survey do
  it { should respond_to :name }
  it { should respond_to :expiry_date }
  it { should respond_to :description }
  it { should respond_to :published }
  it { should respond_to :organization_id }
  it { should respond_to :public }
  it { should respond_to(:auth_key) }
  it { should have_many(:questions).dependent(:destroy) }
  it { should have_many(:responses).dependent(:destroy) }
  it { should have_many(:survey_users).dependent(:destroy) }
  it { should have_many(:participating_organizations).dependent(:destroy) }
  it { should accept_nested_attributes_for :questions }
  it {should belong_to :organization }
  it { should allow_mass_assignment_of(:public) }


  context "when validating" do
    it { should validate_presence_of :name }

    it "should not accept an invalid expiry date" do
      survey = FactoryGirl.build(:survey, :expiry_date => nil)
      survey.should_not be_valid
    end

    it "validates the expiry date to not be in the past" do
      date = Date.new(1990,10,24)
      survey = FactoryGirl.build(:survey, :expiry_date => date)
      survey.should_not be_valid
    end
  end

  context "orders by newest to oldest" do
    it "fetches all surveys in descending order of created_at" do
      survey = FactoryGirl.create(:survey)
      another_survey = FactoryGirl.create(:survey)
      Survey.all.first(2).should == [another_survey, survey]
    end
  end

  context "when duplicating" do
    it "duplicates the nested questions as well" do
      survey = FactoryGirl.create :survey_with_questions
      survey.duplicate.questions.should_not be_empty
    end

    it "doesn't duplicate the other associations" do
      survey = FactoryGirl.create :survey_with_questions
      survey.survey_users << SurveyUser.create
      survey.duplicate.survey_users.should be_empty
    end

    it "unpublishes the duplicated survey" do
      survey = FactoryGirl.create :survey_with_questions
      new_survey = survey.duplicate
      new_survey.should_not be_published
    end

    it "appends (copy) to the survey name" do
      survey = FactoryGirl.create :survey_with_questions
      new_survey = survey.duplicate
      new_survey.name.should =~ /\(copy\)/i
    end
  end

  context "publish" do
    it "should not be published by default" do
      survey = FactoryGirl.create(:survey)
      survey.should_not be_published
    end

    it "changes published to true" do
      survey = FactoryGirl.create(:survey)
      survey.publish
      survey.should be_published
    end

    it "returns a list of published surveys" do
      survey = FactoryGirl.create(:survey)
      another_survey = FactoryGirl.create(:survey, :published => true)
      Survey.unpublished.should include(survey)
      Survey.unpublished.should_not include(another_survey)
    end

    it "returns a list of published surveys" do
      survey = FactoryGirl.create(:survey)
      another_survey = FactoryGirl.create(:survey, :published => true)
      Survey.published.should_not include(survey)
      Survey.published.should include(another_survey)
    end
  end

  context "users" do
    it "returns a list of user-ids the survey is published to" do
      survey = FactoryGirl.create(:survey)
      survey_user = FactoryGirl.create(:survey_user, :survey_id => survey.id)
      survey.user_ids.should == [survey_user.user_id]
    end

    it "returns a list of users the survey is published to" do
      access_token = mock(OAuth2::AccessToken)
      users_response = mock(OAuth2::Response)
      users_response.stub(:parsed).and_return([{"id" => 1, "name" => "Bob"}, {"id" => 2, "name" => "John"}])
      access_token.stub(:get).with('/api/organizations/1/users').and_return(users_response)

      survey = FactoryGirl.create(:survey)
      user = { :id => 1, :name => "Bob"}
      FactoryGirl.create(:survey_user, :survey_id => survey.id, :user_id => user[:id])
      survey.users_for_organization(access_token, 1).map{|user| {:id => user.id, :name => user.name} }.should include user
      survey.users_for_organization(access_token, 1).map{|user| {:id => user.id, :name => user.name} }.should_not include({:id => 2, :name => "John"})
    end

    it "publishes survey to the given users" do
      survey = FactoryGirl.create(:survey)
      users = [1, 2]
      survey.publish_to_users(users)
      survey.user_ids.should == users
    end
  end

  context "participating organizations" do
    it "returns the ids of all participating organizations" do
      survey = FactoryGirl.create(:survey)
      participating_organization = FactoryGirl.create(:participating_organization, :survey_id => survey.id)
      survey.participating_organization_ids.should == [participating_organization.organization_id]
    end

    it "returns a list of organizations the survey is shared with" do
      access_token = mock(OAuth2::AccessToken)
      organizations_response = mock(OAuth2::Response)
      organizations_response.stub(:parsed).and_return([{"id" => 1, "name" => "CSOOrganization"}, {"id" => 2, "name" => "Org name"}])
      access_token.stub(:get).with('/api/organizations').and_return(organizations_response)

      survey = FactoryGirl.create(:survey)
      organization = { :id => 2, :name => "Org name"}
      FactoryGirl.create(:participating_organization, :survey_id => survey.id, :organization_id => organization[:id])
      survey.organizations(access_token, 1).map{|org| {:id => org.id, :name => org.name} }.should include organization
      survey.organizations(access_token, 1).map{|org| {:id => org.id, :name => org.name} }
      .should_not include({:id => 1, :name => "CSOOrganization"})
    end

    it "shares survey with the given organizations" do
      survey = FactoryGirl.create(:survey)
      organizations = [1, 2]
      survey.share_with_organizations(organizations)
      survey.participating_organization_ids.should == organizations
    end
  end

  it "returns a list of first level questions" do
    survey = FactoryGirl.create(:survey)
    question = RadioQuestion.create({content: "Untitled question", survey_id: survey.id, order_number: 1})
    question.options << Option.create(content: "Option", order_number: 2)
    nested_question = RadioQuestion.create({content: "Nested", survey_id: survey.id, order_number: 1, parent_id: question.options.first.id})
    survey.first_level_questions.should include question
    survey.first_level_questions.should_not include nested_question
  end

  context "reports" do
    it "finds all questions which have report data" do
      survey = FactoryGirl.create(:survey)
      question = RadioQuestion.find(FactoryGirl.create(:question_with_options, :survey_id => survey.id).id)
      another_question = RadioQuestion.find(FactoryGirl.create(:question_with_options, :survey_id => survey.id).id)
      5.times { question.answers << FactoryGirl.create(:answer_with_complete_response, :content => question.options.first.content) }
      3.times { question.answers << FactoryGirl.create(:answer_with_complete_response, :content => question.options.last.content) }
      survey.questions_with_report_data.should == [question]
    end
  end

  context "authorization key for public surveys" do
    it "contains a urlsafe random string" do
      survey = FactoryGirl.create :survey, :public => true
      survey.auth_key.should_not be_blank
      survey.auth_key.should =~ /[A-Za-z0-9\-_]+/
    end

    it "is nil for non public surveys" do
      survey = FactoryGirl.create :survey, :public => false
      survey.auth_key.should be_nil
    end

    it "is unique" do
      survey = FactoryGirl.create :survey, :auth_key => 'foo'
      dup_survey = FactoryGirl.build :survey, :auth_key => 'foo'
      dup_survey.should_not be_valid
      dup_survey.errors.full_messages.should include "Auth key has already been taken"
    end
  end

  it "checks whether the survey has expired" do
    survey = FactoryGirl.create(:survey)
    survey.update_attribute(:expiry_date, 2.days.ago)
    survey.should be_expired
    another_survey = FactoryGirl.create(:survey)
    another_survey.should_not be_expired
  end
end
