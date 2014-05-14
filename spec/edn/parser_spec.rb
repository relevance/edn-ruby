require 'spec_helper'

describe EDN::Parser do
  include RantlyHelpers

  let(:parser) { EDN::Parser.new }

  it "can contain comments" do
    edn = ";; This is some sample data\n[1 2 ;; the first two values\n3]"
    EDN.read(edn).should == [1, 2, 3]
  end

  it "can discard using the discard reader macro" do
    edn = "[1 2 #_3 {:foo #_bar :baz}]"
    EDN.read(edn).should == [1, 2, {:foo => :baz}]
  end

  context "element" do
    it "should consume nil" do
      EDN.read("nil")
    end

    it "should consume metadata with the element" do
      EDN.read('^{:doc "test"} [1 2]')
    end
  end

  context "integer" do
    it "should consume integers" do
      rant(RantlyHelpers::INTEGER).each do |int|
        EDN.read int.to_s
      end
    end

    it "should consume integers prefixed with a +" do
      rant(RantlyHelpers::INTEGER).each do |int|
        EDN.read "+#{int.to_i.abs.to_s}"
      end
    end
  end

  context "float" do
    it "should consume simple floats" do
      rant(RantlyHelpers::FLOAT).each do |float|
        EDN.read(float.to_s)
      end
    end

    it "should consume floats with exponents" do
      rant(RantlyHelpers::FLOAT_WITH_EXP).each do |float|
        EDN.read(float.to_s)
      end
    end

    it "should consume floats prefixed with a +" do
      rant(RantlyHelpers::FLOAT).each do |float|
        EDN.read("+#{float.to_f.abs.to_s}")
      end
    end
  end

  context "symbol" do
    it "should consume any symbols" do
      rant(RantlyHelpers::SYMBOL).each do |symbol|
        EDN.read("#{symbol}")
      end
    end

    context "special cases" do
      it "should consume '/'" do
        EDN.read('/')
      end

      it "should consume '.'" do
        EDN.read('.')
      end

      it "should consume '-'" do
        EDN.read('-')
      end
    end
  end

  context "keyword" do
    it "should consume any keywords" do
      rant(RantlyHelpers::SYMBOL).each do |symbol|
        EDN.read(":#{symbol}")
      end
    end
  end

  context "string" do
    it "should consume any string" do
      rant(RantlyHelpers::STRING).each do |string|
        EDN.read(string)
      end
    end
  end

  context "character" do
    it "should consume any character" do
      rant(RantlyHelpers::CHARACTER).each do |char|
        EDN.read(char)
      end
    end
  end

  context "vector" do
    it "should consume an empty vector" do
      EDN.read('[]')
      EDN.read('[  ]')
    end

    it "should consume vectors of mixed elements" do
      rant(RantlyHelpers::VECTOR).each do |vector|
        EDN.read(vector)
      end
    end
  end

  context "list" do
    it "should consume an empty list" do
      EDN.read('()')
      EDN.read('( )')
    end

    it "should consume lists of mixed elements" do
      rant(RantlyHelpers::LIST).each do |list|
        EDN.read(list)
      end
    end
  end

  context "set" do
    it "should consume an empty set" do
      EDN.read('#{}').should == Set.new
      EDN.read('#{ }').should == Set.new
    end

    it "should consume sets of mixed elements" do
      rant(RantlyHelpers::SET).each do |set|
        EDN.read(set)
      end
    end
  end

  context "map" do
    it "should consume maps of mixed elements" do
      rant(RantlyHelpers::MAP).each do |map|
        expect { EDN.read(map) }.not_to raise_error
      end
    end
  end

  context "tagged element" do
    context "#inst" do
      it "should consume #inst" do
        rant(RantlyHelpers::INST).each do |element|
          expect { EDN.read(element) }.not_to raise_error
        end
      end
    end

    it "should consume tagged elements" do
      rant(RantlyHelpers::TAGGED_ELEMENT).each do |element|
        expect { EDN.read(element) }.not_to raise_error
      end
    end
  end
end
