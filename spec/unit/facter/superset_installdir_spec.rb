# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/superset_installdir'

describe :superset_installdir, type: :fact do
  subject(:fact) { Facter.fact(:superset_installdir) }

  before :each do
    # perform any action that should be run before every test
    Facter.clear
    allow(Facter::Core::Execution).to receive(:execute).with('echo $SUPERSET_CONFIG_PATH').and_return('/opt/apache-superset')
  end

  it 'returns a value' do
    expect(fact.value).to eq('/opt/apache-superset')
  end
end
