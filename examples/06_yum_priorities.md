Yum Priorities
==============
There may arise [situations](http://blog.gluster.org/2014/11/installing-glusterfs-3-4-x-3-5-x-or-3-6-0-on-rhel-or-centos-6-6-2/) where a vendor-supplied package is newer than those provided by the gluster.org repositories. In these cases, you can use yum priorities to ensure that the Gluster repository is consulted **before** the vendor channel.

If you use Hiera data:
```
gluster::client: false
gluster::pool: production
gluster::repo: true
gluster::repo::yum::priority: 50
gluster::version: '7.9-1.el7'
```

This ensures that dependency resolution is confined to the repository and revision you specified, and prevents Yum from helpfully trying to use the latest version available.

This is mostly a problem for new systems on which Gluster has not yet been installed.  Once Gluster has been installed, it should remain at the version you specified (unless, of course, you didn't specify -- or explicitly chose 'LATEST' -- in which case you'll always get the latest version.  Caveat emptor.)
