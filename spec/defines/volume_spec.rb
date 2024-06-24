# frozen_string_literal: true

require 'spec_helper'

describe 'gluster::volume', type: :define do
  let(:title) { 'storage1' }
  let(:params) do
    {
      replica: 2,
      bricks: [
        'srv1.local:/export/brick1/brick',
        'srv2.local:/export/brick1/brick',
        'srv1.local:/export/brick2/brick',
        'srv2.local:/export/brick2/brick'
      ],
      options: [
        'server.allow-insecure: on',
        'nfs.ports-insecure: on'
      ]
    }
  end

  describe 'strict variables tests' do
    describe 'missing gluster_binary fact' do
      it { is_expected.to compile.with_all_deps }
    end

    describe 'missing gluster_peer_list fact' do
      let(:facts) do
        {
          gluster_binary: '/usr/sbin/gluster'
        }
      end

      it { is_expected.to compile.with_all_deps }
    end

    describe 'missing gluster_volume_list fact' do
      let(:facts) do
        {
          gluster_binary: '/usr/sbin/gluster',
          gluster_peer_list: 'peer1.example.com,peer2.example.com'
        }
      end

      it { is_expected.to compile.with_all_deps }
    end

    describe 'with all facts' do
      let(:facts) do
        {
          gluster_binary: '/usr/sbin/gluster',
          gluster_peer_list: 'peer1.example.com,peer2.example.com',
          gluster_volume_list: 'gl1.example.com:/glusterfs/backup,gl2.example.com:/glusterfs/backup'
        }
      end

      it { is_expected.to compile.with_all_deps }
    end
  end

  describe 'with nonexistent volume' do
    let(:facts) do
      {
        gluster_binary: '/usr/sbin/gluster',
        gluster_peer_list: 'srv1.local,srv2.local',
        gluster_volume_list: 'srv1.local:/glusterfs/backup,srv2.local:/glusterfs/backup'
      }
    end

    describe 'with minimal params' do
      let(:args) do
        'replica 2 transport tcp srv1.local:/export/brick1/brick srv2.local:/export/brick1/brick srv1.local:/export/brick2/brick srv2.local:/export/brick2/brick'
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_exec("gluster create volume #{title}").with(
          command: "/usr/sbin/gluster volume create #{title} #{args}"
        )
      end
    end

    describe 'with force' do
      let(:params) do
        super().merge(force: true)
      end
      let(:args) do
        'replica 2 transport tcp srv1.local:/export/brick1/brick srv2.local:/export/brick1/brick srv1.local:/export/brick2/brick srv2.local:/export/brick2/brick force'
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_exec("gluster create volume #{title}").with(
          command: "/usr/sbin/gluster volume create #{title} #{args}"
        )
      end
    end
  end

  describe 'with existent volume' do
    let(:title)  { 'volume1' }
    let(:facts) do
      {
        gluster_binary: '/usr/sbin/gluster',
        gluster_peer_list: 'srv1.local,srv2.local',
        gluster_volume_list: 'volume1',
        gluster_volume_volume1_bricks: 'srv1.local:/export/volume1/brick,srv2.local:/export/volume1/brick',
      }
    end
    let(:params) do
      {
        replica: 2,
        bricks: [
          'srv1.local:/export/volume1/brick',
          'srv2.local:/export/volume1/brick',
        ],
      }
    end

    it { is_expected.to compile.with_all_deps }
  end

  describe 'single node' do
    let(:facts) do
      {
        gluster_binary: '/usr/sbin/gluster',
        gluster_peer_count: 0,
        gluster_peer_list: ''
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec("gluster create volume #{title}") }
  end

  describe 'with empty options' do
    let(:facts) do
      {
        gluster_binary: '/usr/sbin/gluster'
      }
    end
    let(:params) do
      super().merge(options: [])
    end

    it { is_expected.to compile.with_all_deps }
  end
end
