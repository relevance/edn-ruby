require 'spec_helper'

describe EDN::StreamReader do
  let(:forms)  { [] }
  let(:reader) { EDN::StreamReader.new(lambda {|form| forms << form}) }

  before do
    forms.clear
    reader.reset
  end

  it "should read full form" do
    reader << "1"
    forms.count.should == 1
    forms.first.should == 1
  end

  it "should read form in chunks" do
    reader << "[1 2"
    forms.count.should == 0
    reader << "]"
    forms.count.should == 1
    forms.first.should == [1, 2]
  end

  it "should read multiple forms in chunks" do
    reader << "[1 2"
    forms.count.should == 0
    reader << "] {:a 1, :b "
    forms.count.should == 1
    reader << "2}"
    forms.count.should == 2
  end

  it "should read multiple forms in the same chunk" do
    reader << "[1 2] [3 4]"
    forms.count.should == 2
  end

  it "should support chaining" do
    reader << "1" << "2"
    forms.count.should == 2
  end

end
