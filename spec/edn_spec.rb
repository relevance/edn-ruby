require 'spec_helper'

describe EDN do
  include RantlyHelpers

  context "#read" do
    it "reads single values" do
      EDN.read("1").should == 1
      EDN.read("3.14").should == 3.14
      EDN.read('"hello\nworld"').should == "hello\nworld"
      EDN.read(':hello').should == :hello
      EDN.read(':hello/world').should == :"hello/world"
      EDN.read('hello').should == EDN::Type::Symbol.new('hello')
      EDN.read('hello/world').should == EDN::Type::Symbol.new('hello/world')
      EDN.read('true').should == true
      EDN.read('false').should == false
      EDN.read('nil').should == nil
      EDN.read('#"hello"').should == /hello/
      EDN.read('\c').should == "c"
    end

    it "reads vectors" do
      EDN.read('[]').should == []
      EDN.read('[1]').should == [1]
      EDN.read('["hello" 1 2]').should == ['hello', 1, 2]
      EDN.read('[[1 [:hi]]]').should == [[1, [:hi]]]
    end

    it "reads lists" do
      EDN.read('()').should == []
      EDN.read('(1)').should == [1]
      EDN.read('("hello" 1 2)').should == ['hello', 1, 2]
      EDN.read('((1 (:hi)))').should == [[1, [:hi]]]
    end

    it "reads maps" do
      EDN.read('{}').should == {}
      EDN.read('{:a :b}').should == {:a => :b}
      EDN.read('{:a 1, :b 2}').should == {:a => 1, :b => 2}
      EDN.read('{:a {:b :c}}').should == {:a => {:b => :c}}
    end

    it "reads sets" do
      EDN.read('#{}').should == Set.new
      EDN.read('#{1}').should == Set[1]
      EDN.read('#{1 "abc"}').should == Set[1, "abc"]
      EDN.read('#{1 #{:abc}}').should == Set[1, Set[:abc]]
    end

    it "reads any valid value" do
      values = rant(RantlyHelpers::VALUE)
      values.each do |value|
        if value =~ /^(#.+ )?nil$/
          EDN.read(value).should be_nil
        else
          EDN.read(value).should_not be_nil
        end
      end
    end
  end
end
