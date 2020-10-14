# frozen_string_literal: true

require 'spec_helper'

describe 'vcsdeploy' do
  let(:title) { '/path/to/deployment' }
  let(:params) do
    {
      source: 'https://github.com/opus-codium/puppet-vcsdeploy.git',
      after_fetch_command: '/usr/local/bin/meta-vcsdeploy',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
