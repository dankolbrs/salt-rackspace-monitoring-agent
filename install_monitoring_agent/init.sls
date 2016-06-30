
rackspace-monitoring-agent-repo:
  pkgrepo.managed:
    {% if grains.get('os', '').lower() == 'centos' -%}
    - baseurl: http://stable.packages.cloudmonitoring.rackspace.com/{{ grains.get('os', '').lower() }}-{{ grains.get('osmajorrelease', '').lower() }}-{{ grains.get('cpuarch', '') }}
    - gpgkey: https://monitoring.api.rackspacecloud.com/pki/agent/{{ grains.get('os', '').lower() }}-{{ grains.get("osmajorrelease", '') }}.asc
    {% elif grains['os'].lower() == 'debian' -%}
    - name: deb http://stable.packages.cloudmonitoring.rackspace.com/{{ grains['osfullname'].lower() }}-{{ grains['oscodename'] }}-{{ grains["cpuarch"] }} cloudmonitoring main
    - key_url: https://monitoring.api.rackspacecloud.com/pki/agent/linux.asc
    {% elif grains['os'].lower() == 'ubuntu' -%}
    - name: deb http://stable.packages.cloudmonitoring.rackspace.com/{{ grains['osfinger'].lower() }}-{{ grains['cpuarch'] }} cloudmonitoring main
    - key_url: https://monitoring.api.rackspacecloud.com/pki/agent/linux.asc
    {%- endif %}
    - humanname: rackspace-monitoring-agent

{% for plugin in salt['pillar.get']('plugins') %}
/usr/lib/rackspace-monitoring-agent/plugins/{{ plugin }}:
  file.managed:
    - source: salt://install_monitoring_agent/plugins/{{ plugin }}
    - makedirs: true
    - mode: 775
{% endfor %}

##================Checks===================##
##Run through checks enabled via pillar data

##------------Agent.Network checks---------------##
##This uses custom grain to provide a list of eth devices (removing lo)
{% if 'network' in salt['pillar.get']('checks') %}
{% set check = 'network' %}
{% for interface in grains.get('eth_interfaces', []) %}
/etc/rackspace-monitoring-agent.conf.d/{{ check }}-{{ interface }}.yaml:
  file.managed:
    - source: salt://install_monitoring_agent/files/{{ check }}.yaml.jinja
    - makedirs: true
    - template: jinja
    - context:
        interface: {{ interface }}
{% endfor %}
{% endif %}
##------------End Agent.Network checks---------------##

##-----Agent.filesystem check---------------##
{% if 'disk' in salt['pillar.get']('checks') -%}
{% set check = 'disk' %}
##Grab each mounted device from custom grain
{% for devices in grains.get('mounted_devices', []) -%}
{% for device in devices.iterkeys() %}
{% set mount_index = device.split('/')|length -1 -%}
{% set dev_abbr = device.split('/')[mount_index] -%}
## dev_abbr = abbrev device, device = device full, devices[device] = mount location
##ex. dev_abbr= centos-root,  device = /dev/mapper/centos-root, devices[device] = /
/etc/rackspace-monitoring-agent.conf.d/{{ check }}-{{ dev_abbr }}.yaml:
  file.managed:
    - source: salt://install_monitoring_agent/files/{{ check }}.yaml.jinja
    - makedirs: true
    - template: jinja
    - context:
        dev_abbr: {{ dev_abbr }}
        device: {{ device }}
        mountpoint: {{ devices[device] }}
{% endfor %}
{%- endfor %}
{% endif %}
##-----End Disk Check -----------##


##--------agent.load check---------##
{% if 'load' in salt['pillar.get']('checks') -%}
{% set check = 'load' %}
/etc/rackspace-monitoring-agent.conf.d/{{ check }}.yaml:
  file.managed:
    - source: salt://install_monitoring_agent/files/{{ check }}.yaml.jinja
    - makedirs: true
    - template: jinja
    - context:
{% endif %}
##--------end agent.load check---------##


##--------agent.memory check---------##
{% if 'memory' in salt['pillar.get']('checks') -%}
{% set check = 'memory' %}
/etc/rackspace-monitoring-agent.conf.d/{{ check }}.yaml:
  file.managed:
    - source: salt://install_monitoring_agent/files/{{ check }}.yaml.jinja
    - makedirs: true
    - template: jinja
    - context:
{% endif %}
##--------end agent.memory check---------##


##--------agent.cpu check---------##
{% if 'cpu' in salt['pillar.get']('checks') -%}
{% set check = 'cpu' %}
/etc/rackspace-monitoring-agent.conf.d/{{ check }}.yaml:
  file.managed:
    - source: salt://install_monitoring_agent/files/{{ check }}.yaml.jinja
    - makedirs: true
    - template: jinja
    - context:
{% endif %}
##--------agent.cpu check---------##

##------------agent.remote curl_check.sh---------##
##Pull the URL included in the check
{% if 'curl' in salt['pillar.get']('checks') %}
{% set check = 'curl' %}
{% set url=salt['pillar.get']("checks:curl", "")[0] -%}
{% set subdomain = url.split('/')[2].split('.')[0] -%}
##requires curl packages
curl:
  pkg.installed: []

##url is the url, subdomain is first part for labeling
/etc/rackspace-monitoring-agent.conf.d/{{ check }}-{{ subdomain }}.yaml:
  file.managed:
    - source: salt://install_monitoring_agent/files/{{check}}.yaml.jinja
    - makedirs: true
    - template: jinja
    - require:
      - pkg: curl
{% endif %}
##-------End Curl Check -----------##

##================End-Checks===================##

rackspace-monitoring-agent:
  pkg.installed: []
  cmd.run:
    - name: rackspace-monitoring-agent --setup --auto-create-entity --username {{ salt['pillar.get']('rackspace:username') }} --apikey {{ salt['pillar.get']('rackspace:apikey') }}
    - require:
      - pkg: rackspace-monitoring-agent
    - unless: touch /etc/rackspace-monitoring-agent.cfg && grep "monitoring" /etc/rackspace-monitoring-agent.cfg

restart_agent:
  service.running:
    - name: rackspace-monitoring-agent
    - restart: true
    - watch:
      - pkg: rackspace-monitoring-agent
    - enable: true
    - require:
      - pkg: rackspace-monitoring-agent
