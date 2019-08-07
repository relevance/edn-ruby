# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EDN::Reader do
  let(:reader) { EDN::Reader.new('[1 2] 3 :a {:b c} ') }

  it 'should read each value' do
    expect(reader.read).to eq([1, 2])
    expect(reader.read).to eq(3)
    expect(reader.read).to eq(:a)
    expect(reader.read).to eq(b: ~'c')
  end

  it 'should respond to each' do
    reader.each do |element|
      expect(element).not_to be_nil
    end
  end

  it 'returns a special end of file value if asked' do
    4.times { expect(reader.read(:the_end)).not_to eq(:the_end) }
    expect(reader.read(:no_more)).to eq(:no_more)
  end
end
