#! /usr/bin/env python
# used to get network interface as list in grains
# Dan Kolb <dan.kolb@rackspace.com> June 2016

import salt.utils.network
import salt.modules.cmdmod

def get_eth_devices():
    grains = {}
    interfaces = salt.utils.network.interfaces().keys()
    #remove lo
    interfaces.remove('lo')
    grains["eth_interfaces"] = interfaces
    return grains

def get_mounted_devices():
    grains = {}
    mounts_list = []
    mounts = []
    __salt__ = {'cmd.run': salt.modules.cmdmod._run_quiet}
    mounts_list = __salt__['cmd.run']('df -h').split('\n')
    for mount in mounts_list:
        if mount.find('/dev/') == 0:
            device = mount.split(' ')[0]
            mount_point = mount.split(' ')[len(mount.split(' ')) -1]
            mounts.append({device: mount_point})
    grains["mounted_devices"] = mounts
    return grains
    
