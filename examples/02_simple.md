Simple Gluster Setup
====================
This is effectively the same as 01_simple, but uses explicit class declarations.

Let's assume you have two servers, srv1.local and srv2.local.  On each of these servers you have a partition mounted at /export/brick1.  Following Gluster best practices you create a "brick" directory on each partition:

    # mkdir /export/brick1/brick

To create a simple two-node replicated Gluster volume, you could use the following Puppet manifest:

    node /srv[1-2].local/ {
      # first, install the upstream Gluster packages
      class { gluster::install:
        server  => true,
        client  => true,
        repo    => true,
        version => '7.9',
      }

      # make sure the service is started
      class { gluster::service:
        ensure  => running,
        require => Class[::gluster::install],
      }

      # now establish a peering relationship
      gluster::peer { [ 'srv1.local', 'srv2.local' ]:
        pool    => 'production',
        require => Class[::gluster::service],
      }

      gluster::volume { 'g0':
        replica => 2,
        bricks  => [ 'srv1.local:/export/brick1/brick',
                     'srv2.local:/export/brick1/brick', ],
        options => [ 'nfs.disable: true' ],
        require => Gluster::Peer[ [ 'srv1.local', 'srv2.local' ] ],
      }
    }

That's it!

If you wanted to mount this Gluster volume on each of these servers at `/gluster/g0`, simply add the following:

    gluster::mount { '/gluster/g0':
      volume  => 'srv1.local:/g0',
      atboot  => true,
      options => 'noatime,nodev,noexec,nosuid',
    }

