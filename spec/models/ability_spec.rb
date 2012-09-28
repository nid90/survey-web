require "cancan/matchers"

describe "Abilities" do
  subject { ability }
  let(:base_user_info) {
    {
      :name => "John",
      :email => "john@gmail.com",
      :org_id => 5,
      :user_id => 6
    }
  }
  let(:ability){ Ability.new(user_info) }

  context "for Surveys" do
    context "when is a admin" do
      let(:user_info) { base_user_info.merge(:role => 'admin') }

      it { should be_able_to(:read, Survey.new) }
      it { should be_able_to(:create, Survey.new) }
      it { should be_able_to(:publish, Survey.new) }
      it { should be_able_to(:edit, Survey.new) }
      it { should be_able_to(:share, Survey.new) }
      it { should be_able_to(:destroy, Survey.new) }
    end

    context "when is a cso admin" do
      let(:user_info) { base_user_info.merge(:role => 'cso_admin') }

      it { should be_able_to(:create, Survey.new) }
      it { should be_able_to(:publish, Survey.new) }
      it { should be_able_to(:edit, Survey.new) }
      it { should be_able_to(:share, Survey.new) }

      context "when destroying" do

        specify "should be able to destroy surveys belonging to the same organization" do
          survey = FactoryGirl.create(:survey, :organization_id => 5)
          ability.should be_able_to(:destroy, survey)
        end

        specify "should not be able to destroy surveys belonging to another organization" do
          survey = FactoryGirl.create(:survey, :organization_id => 6)
          ability.should_not be_able_to(:destroy, survey)
        end

      end

      context "when reading" do

        specify "should be able to read surveys belonging to the same organization" do
          survey = FactoryGirl.create(:survey, :organization_id => 5)
          ability.should be_able_to(:read, survey)
        end

        specify "should not be able to read surveys belonging to another organization" do
          survey = FactoryGirl.create(:survey, :organization_id => 6)
          ability.should_not be_able_to(:read, survey)
        end

      end
    end

    context "when is a regular user" do
      let(:user_info) { base_user_info.merge(:role => 'user') }

      it { should_not be_able_to(:create, Survey.new) }
      it { should_not be_able_to(:publish, Survey.new) }
      it { should_not be_able_to(:edit, Survey.new) }
      it { should_not be_able_to(:share, Survey.new) }
      it { should_not be_able_to(:destroy, Survey.new) }

      specify "should be able to read surveys shared with him" do
        survey = FactoryGirl.create(:survey, :organization_id => 5)
        SurveyUser.create(:survey_id => survey.id, :user_id => user_info[:user_id])
        ability.should be_able_to(:read, survey)
      end

      specify "should not be able to read surveys not shared with him" do
        survey = FactoryGirl.create(:survey, :organization_id => 6)
        SurveyUser.create(:survey_id => survey.id, :user_id => 123)
        ability.should_not be_able_to(:read, survey)
      end
    end
  end
end