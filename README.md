##Salt install rackspace-monitoring-agent
Salt state file for installing rackspace-monitoring-agent. Requires some pillar data. This can be done as a pillar, or in a vagrantfile. For testing, this is usually better setting up a `/srv/salt/pillar` directory as the vagrantfile option passes pillar data during the `salt.run_highstate` portion.
```
rackspace:
  username: <RACKSPACE_USER>
  apikey: <RACKSPACE_KEY>
  notification_plan_id: <MONITORING_NOTIFICATION_PLAN>
checks:
  load:
    critical: 90
    warning: 80
  cpu:
    critical: 90
    warning: 80
  network:
    alarms: none
  curl:
    - https://gitlab-int.dankolb.net
  memory:
    critical: 90
    warning: 80
  disk:
    critical: 90
    warning: 80

plugins:
  - mongodb_stats.py
  - curl_check.sh
```

Or in vagrant:
```
      salt.pillar({"rackspace" => {
        "username" => "my_rackspace_user",
        "apikey" => "my_rackspace_users_api_key",
        "notification_plan_id" => "notification_plan_for_agent_checks"
        }
      })
      salt.pillar({"checks" => ["disk", "load"]})

```

###Adding checks
Rackspace-monitoring-agent can create checks via [yaml files](https://developer.rackspace.com/docs/rackspace-monitoring/v1/developer-guide/#configure-agent-with-yaml). On adding check yaml files, restarting the agent will create checks/alarms as dicated.

To add a check, add a new file template in files/, a new block in init.sls, and the check and arguments in pillar data. If the check uses a [plugin](https://github.com/racker/rackspace-monitoring-agent-plugins-contrib), add that file (executable) into the plugins/ directory and add that file to the `plugins` pillar data.
```
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
```

