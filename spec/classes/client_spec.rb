require 'spec_helper'

describe 'gluster::client', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let(:facts) do
        facts
      end
      context 'with all defaults' do
        it { should contain_class('gluster::client') }
        it { should compile.with_all_deps }
        it 'should include gluster::install' do
          should create_class('gluster::install').with(
            repo: true,
            client_package: 'glusterfs-fuse',
            version: 'LATEST',
          )
        end
      end
      context 'when a version number is specified' do
        let :params do { version: '3.6.1' } end
        it 'should include gluster::install with version 3.6.1' do
          should create_class('gluster::install').with(
            repo: true,
            client_package: 'glusterfs-fuse',
            version: '3.6.1',
          )
        end
      end
      context 'when repo is false' do
        let :params do { repo: false } end
        it 'should include gluster::install with repo=>false' do
          should create_class('gluster::install').with(
            repo: false,
            client_package: 'glusterfs-fuse',
            version: 'LATEST',
          )
        end
      end
    end
  end
end
