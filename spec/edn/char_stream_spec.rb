require 'spec_helper'

describe EDN::CharStream do
  it "reads a stream in order" do
    s = EDN::CharStream.new(io_for("abc"))
    s.current.should == "a"
    s.advance.should == "b"
    s.advance.should == "c"
    s.advance.should == :eof
    s.current.should == :eof
  end

  it "keeps returning the current until your advance" do
    s = EDN::CharStream.new(io_for("abc"))
    s.current.should == "a"
    s.current.should == "a"
    s.advance.should == "b"
  end

  it "knows if the current char is a digit" do
    s = EDN::CharStream.new(io_for("4f"))
    s.digit?.should be_true
    s.advance
    s.digit?.should be_false
  end

  it "knows if the current char is an alpha" do
    s = EDN::CharStream.new(io_for("a9"))
    s.alpha?.should be_true
    s.advance
    s.alpha?.should be_false
  end

  it "knows if the current char is whitespace" do
    s = EDN::CharStream.new(io_for("a b\nc\td,"))
    s.ws?.should be_false # a

    s.advance
    s.ws?.should be_true # " "

    s.advance
    s.ws?.should be_false # b

    s.advance
    s.ws?.should be_true # \n

    s.advance
    s.ws?.should be_false # c

    s.advance
    s.ws?.should be_true # \t

    s.advance
    s.ws?.should be_false # d

    s.advance
    s.ws?.should be_true # ,
  end

  it "knows if the current char is a newline" do
    s = EDN::CharStream.new(io_for("a\nb\rc"))
    s.newline?.should be_false # a

    s.advance
    s.newline?.should be_true # \n

    s.advance
    s.newline?.should be_false # b

    s.advance
    s.newline?.should be_true # \r

    s.advance
    s.newline?.should be_false # c
  end

  it "knows if it is at the eof" do
    s = EDN::CharStream.new(io_for("abc"))
    s.eof?.should be_false # a
    s.advance
    s.eof?.should be_false # b
    s.advance
    s.eof?.should be_false # c
    s.advance
    s.eof?.should be_true
  end

  it "knows how to skip past a char" do
    s = EDN::CharStream.new(io_for("abc"))
    s.skip_past("a").should == "a"
    s.current.should == "b"
  end

  it "knows how not to skip a char" do
    s = EDN::CharStream.new(io_for("abc"))
    s.skip_past("X").should be_nil
  end

  it "knows how skip to the end of a line" do
    s = EDN::CharStream.new(io_for("abc\ndef"))
    s.skip_to_eol
    s.current.should == "\n"
    s.advance.should == "d"
  end

  it "knows how skip whitespace" do
    s = EDN::CharStream.new(io_for("  \n \t,,,,abc"))
    s.skip_ws
    s.current.should == "a"
  end
end
