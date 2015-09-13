require 'spec_helper_acceptance'

describe 'manage_ebs_crossaz class' do

  include_context "hieradata_common"

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      class { 'manage_ebs_crossaz': }
      EOS

      apply_opts = {
        :catch_failures => true,
        :debug => ENV['BEAKER_puppet_debug'],
      }

      # Run it twice and test for idempotency
      expect(apply_manifest(pp, apply_opts ).exit_code).to_not eq(1)
      expect(apply_manifest(pp, apply_opts ).exit_code).to be_zero

    end

    describe package('manage_ebs_crossaz') do
      it { is_expected.to be_installed }
    end

    describe service('manage_ebs_crossaz') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end


end
