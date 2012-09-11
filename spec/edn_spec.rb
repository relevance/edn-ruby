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
      EDN.read('\c').should == "c"
    end

    it "reads #inst tagged values" do
      EDN.read('#inst "2012-09-10T16:16:03-04:00"').should == DateTime.new(2012, 9, 10, 16, 16, 3, '-04:00')
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
        if value == "nil"
          EDN.read(value).should be_nil
        else
          EDN.read(value).should_not be_nil
        end
      end
    end
  end

  context "writing" do
    it "writes any valid value" do
      values = rant(RantlyHelpers::VALUE)
      values.each do |value|
        expect {
          EDN.read(value).to_edn
        }.to_not raise_error
      end
    end

    it "writes equivalent edn to what it reads" do
      values = rant(RantlyHelpers::VALUE)
      values.each do |value|
        ruby_value = EDN.read(value)
        ruby_value.should == EDN.read(ruby_value.to_edn)
      end
    end
  end
end
