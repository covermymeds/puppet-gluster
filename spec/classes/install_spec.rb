require 'spec_helper'

describe 'gluster::install', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      let :pre_condition do
        'require ::gluster::service'
      end
      context 'with defaults' do
        it { should compile.with_all_deps }
        it 'creates gluster::repo' do
          should create_class('gluster::repo').with(
            version: 'LATEST'
          )
        end
        case facts[:osfamily]
        when 'Redhat'
          it 'installs glusterfs package for a server' do
            should create_package('glusterfs')
          end
          it 'installs glusterfs-fuse for a client' do
            should create_package('glusterfs-fuse')
          end
        when 'Debian'
          it 'installs glusterfs package for a server' do
            should create_package('glusterfs-server')
          end
          it 'installs glusterfs-fuse for a client' do
            should create_package('glusterfs-client')
          end
        end
      end
      context 'when repo is false' do
        let :params do
          { repo: false }
        end
        it 'does not create gluster::repo' do
          should_not create_class('gluster::repo')
        end
      end
      context 'when client is false' do
        let :params do
          { client: false }
        end
        case facts[:osfamily]
        when 'Redhat'
          it 'does not install glusterfs-fuse package' do
            should_not create_package('glusterfs-fuse')
          end
        when 'Debian'
          it 'does not install glusterfs-fuse package' do
            should_not create_package('glusterfs-client')
          end
        end
      end
      context 'when server is false' do
        let :params do
          { server: false }
        end
        case facts[:osfamily]
        when 'Redhat'
          it 'does not install glusterfs' do
            should_not create_package('glusterfs')
          end
        when 'Debian'
          it 'does not install glusterfs' do
            should_not create_package('glusterfs-server')
          end
        end
      end
      context 'installing on an unsupported architecture' do
        let :facts do
          super().merge(
            architecture: 'zLinux'
          )
        end
        it 'does not install' do
          expect do
            should create_class('gluster::repo')
          end.to raise_error(Puppet::Error, %r{not yet supported})
        end
      end
    end
  end
end
