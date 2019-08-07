# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe EDN do
  include RantlyHelpers

  context 'Exemplar' do
    Dir["#{File.dirname(__FILE__)}/exemplars/*.edn"].each do |edn_file|
      rb_file = edn_file.sub(/\.edn$/, '.rb')
      it "reads file #{File.basename(edn_file)} correctly" do
        expected = Module.instance_eval(File.read(rb_file))
        actual = EDN.read(File.read(edn_file))
        expect(actual).to eq(expected)
      end

      it "round trips the value in #{File.basename(edn_file)} correctly" do
        expected = Module.instance_eval(File.read(rb_file))
        actual = EDN.read(File.read(edn_file))
        round_trip = EDN.read(actual.to_edn)
        expect(round_trip).to eq(expected)
      end
    end
  end

  context '#read' do
    it 'reads from a stream' do
      io = StringIO.new('123')
      expect(EDN.read(io)).to eq(123)
    end

    it 'reads mutiple values from a stream' do
      io = StringIO.new('123 456 789')
      expect(EDN.read(io)).to eq(123)
      expect(EDN.read(io)).to eq(456)
      expect(EDN.read(io)).to eq(789)
    end

    it 'raises an exception on eof by default' do
      expect { EDN.read('') }.to raise_error('Unexpected end of file')
    end

    # it "allows you to specify an eof value" do
    #  io = StringIO.new("123 456")
    #  EDN.read(io, :my_eof).should == 123
    #  EDN.read(io, :my_eof).should == 456
    #  EDN.read(io, :my_eof).should == :my_eof
    # end

    it 'allows you to specify nil as an eof value' do
      expect(EDN.read('', nil)).to be_nil
    end
  end

  context 'reading data' do
    it 'treats carriage returns like whitespace' do
      expect(EDN.read("\r\n[\r\n]\r\n")).to eq([])
      expect(EDN.read("\r[\r]\r\r")).to eq([])
    end

    it 'reads any valid element' do
      elements = rant(RantlyHelpers::ELEMENT)
      elements.each do |element|
        begin
          if element == 'nil'
            expect(EDN.read(element)).to be_nil
          else
            expect(EDN.read(element)).not_to be_nil
          end
        rescue StandardError => e
          puts "Bad element: #{element}"
          raise e
        end
      end
    end
  end

  context '#register' do
    it 'uses the identity function when no handler is given' do
      EDN.register 'some/tag'
      expect(EDN.read('#some/tag {}')).to be_instance_of(Hash)
    end
  end

  context 'writing' do
    it 'writes any valid element' do
      elements = rant(RantlyHelpers::ELEMENT)
      elements.each do |element|
        expect do
          begin
            EDN.read(element).to_edn
          rescue StandardError => e
            puts "Bad element: #{element}"
            raise e
          end
        end.to_not raise_error
      end
    end

    it 'writes equivalent edn to what it reads' do
      elements = rant(RantlyHelpers::ELEMENT)
      elements.each do |element|
        ruby_element = EDN.read(element)
        expect(ruby_element).to eq(EDN.read(ruby_element.to_edn))

        if ruby_element.respond_to?(:metadata)
          expect(ruby_element.metadata).to eq(EDN.read(ruby_element.to_edn).metadata)
        end
      end
    end
  end
end
