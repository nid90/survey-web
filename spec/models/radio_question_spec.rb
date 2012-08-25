require 'spec_helper'

describe RadioQuestion do
  it { should respond_to :content }
  it { should belong_to :survey }
  it { should have_many(:answers).dependent(:destroy) }
  it { should have_many(:options).dependent(:destroy) }
  it { should validate_presence_of :content }
  it { should respond_to :mandatory }
  it { should respond_to :image }
  it { should accept_nested_attributes_for(:options) }

  it "is a question with type = 'RadioQuestion'" do
    RadioQuestion.create(:content => "hello")
    question = Question.find_by_content("hello")
    question.should be_a RadioQuestion
    question.type.should == "RadioQuestion"
  end  
end