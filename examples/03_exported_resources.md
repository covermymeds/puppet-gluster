Gluster with Exported Resources
===============================

If you are using [PuppetDB](https://docs.puppetlabs.com/puppetdb/) then you can use [exported resources](https://docs.puppetlabs.com/puppet/3/reference/lang_exported.html) with this Gluster module to greatly simplify your manifests.

When using exported resources, each Gluster server will export a `gluster::peer` resource for itself, and then collect all the other `gluster::peer` resources for the same `pool` value.

Again, assuming two servers each with one brick:

    node /srv[1-2].local/ {
      class { gluster:
        client  => true,
        repo    => true,
        pool    => 'production',
        version => '7.9',
        volumes => {
          'g0' => {
            replica => 2,
            bricks  => [ 'srv1.local:/export/brick1/brick',
                         'srv2.local:/export/brick1/brick', ],
            options => [ 'nfs.disable: true' ],
          }
        }
      }

      gluster::mount { '/gluster/g0':
        volume  => 'srv1.local:/g0',
        atboot  => true,
        options => 'noatime,nodev,noexec,nosuid',
      }
    }

