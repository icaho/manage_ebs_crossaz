require 'spec_helper'

os = ENV['BEAKER_set'] ||= 'centos6'

case os
when /default/
  osversion = '6'
when /centos6/
  osversion = '6'
when /centos7/
  osversion = '7'
else
  raise "Operating system: #{os} is not supported"
end

describe 'manage_ebs_crossaz' do

  include_context "hieradata"
  include_context "facter"

  context 'supported operating systems' do
    describe "manage_ebs_crossaz class without any parameters on CentOS #{osversion}" do
      let(:params) {{ }}
      let(:facts) do
        default_facts.merge({
        :operatingsystemmajrelease => osversion,
        })
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('manage_ebs_crossaz') }
      it { is_expected.to contain_class('manage_ebs_crossaz::params') }

      it { is_expected.to contain_class('manage_ebs_crossaz::install').that_comes_before('manage_ebs_crossaz::config') }
      it { is_expected.to contain_class('manage_ebs_crossaz::config') }

      it { is_expected.to contain_package('ruby').with_ensure('installed') }
      it { is_expected.to contain_package('rubygems').with_ensure('installed') }
      it { is_expected.to contain_package('aws-sdk').with_ensure('installed') }
      it { is_expected.to contain_file('/usr/bin/manage_ebs').with_ensure('file') }

    end
  end

end
