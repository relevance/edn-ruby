require 'spec_helper'

describe EDN::Transform do
  context "integer" do
    it "should emit an integer" do
      subject.apply(:integer => "1").should == 1
    end
  end

  context "float" do
    it "should emit an float" do
      subject.apply(:float => "1.0").should == 1.0
    end
  end

  context "string" do
    it "should emit a string with control characters substituted" do
      subject.apply(:string => 'hello\nworld').should == "hello\nworld"
    end

    it "should not evaluate interpolated Ruby code" do
      subject.apply(:string => 'hello\n#{world}').should == "hello\n\#{world}"
    end
  end

  context "keyword" do
    it "should emit a Ruby symbol" do
      subject.apply(:keyword => "test").should == :test
    end
  end

  context "symbol" do
    it "should emit an EDN symbol" do
      subject.apply(:symbol => "test").should == EDN::Type::Symbol.new('test')
    end
  end

  context "boolean" do
    it "should emit true or false" do
      subject.apply(:boolean => "true").should == true
      subject.apply(:boolean => "false").should == false
    end
  end

  context "nil" do
    it "should emit nil" do
      subject.apply(:nil => "nil").should == nil
    end
  end

  context "regexp" do
    it "should emit a regexp" do
      regexp = subject.apply(:regexp => 'hello\nworld')
      regexp.should be_a(Regexp)
      regexp.should match("hello\nworld")
    end
  end

  context "character" do
    it "should emit a string" do
      subject.apply(:character => "&").should == "&"
    end

    it "should handle newline, space, and tab special cases" do
      subject.apply(:character => "newline").should == "\n"
      subject.apply(:character => "space").should == " "
      subject.apply(:character => "tab").should == "\t"
    end
  end

  context "vector" do
    it "should emit an array" do
      subject.apply(:vector => []).should == []
      subject.apply(:vector => [{:integer => "1"}, {:string => "abc"}]).should == [1, "abc"]
      subject.apply(:vector => [{:vector => [{:integer => "1"}, {:string => "abc"}]}, {:float => "3.14"}]).should == [[1, "abc"], 3.14]
    end
  end

  context "list" do
    it "should emit a list" do
      subject.apply(:list => []).should == EDN::Type::List.new
      subject.apply(:list => [{:integer => "1"}, {:string => "abc"}]).should == EDN::Type::List.new(1, "abc")
      subject.apply(:list => [{:list => [{:integer => "1"}, {:string => "abc"}]}, {:float => "3.14"}]).should == \
        EDN::Type::List.new(EDN::Type::List.new(1, "abc"), 3.14)
    end

    it "should be type-compatible with arrays" do
      subject.apply(:list => [{:integer => "1"}, {:string => "abc"}]).should == [1, "abc"]
    end
  end

  context "set" do
    it "should emit a set" do
      subject.apply(:set => []).should == Set.new
      subject.apply(:set => [1, "abc", 2]).should == Set.new([1, "abc", 2])
    end
  end

  context "map" do
    it "should emit a hash" do
      map_tree = {:map=>
        [ {:key=>{:keyword=>{:symbol=>"a"}}, :value=>{:integer=>"1"}},
          {:key=>{:keyword=>{:symbol=>"b"}}, :value=>{:integer=>"2"}}
        ]
      }

      subject.apply(map_tree).should == {:a => 1, :b => 2}
    end

    it "should work with nested maps" do
      map_tree = {:map=>
        [{:key=>{:keyword=>{:symbol=>"a"}}, :value=>{:integer=>"1"}},
          {:key=>{:keyword=>{:symbol=>"b"}}, :value=>{:integer=>"2"}},
          {:key=>
            {:map=>
              [{:key=>{:keyword=>{:symbol=>"c"}}, :value=>{:integer=>"3"}}]},
            :value=>{:integer=>"4"}}]}
      subject.apply(map_tree).should == {:a => 1, :b => 2, {:c => 3} => 4}
    end
  end

  context "tagged value" do
    it "should emit the base value if the tag is not registered" do
      subject.apply(:tagged_value => {
                      :tag => 'uri', :value => {:string => 'http://google.com'}
                    }).should == "http://google.com"
    end

    it "should emit the transformed value if the tag is registered" do
      EDN.register("uri", lambda { |uri| URI(uri) })
      subject.apply(:tagged_value => {
                      :tag => 'uri', :value => {:string => 'http://google.com'}
                    }).should == URI("http://google.com")
      EDN.unregister("uri") # cleanup
    end
  end
end
