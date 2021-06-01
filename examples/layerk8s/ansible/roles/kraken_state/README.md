# roles/kraken-state

The kraken-state role will generate a kraken statefile based on inventory information.

See [defaults/main.yml](defaults/main.yml) for available configuration.

Below is an example of inventory structure.  In general, any service or extension with a template with the name `<key>.<module|extension>.json.j2` is supported for state generation.

```yaml
kraken_parent_id: "123e4567-e89b-12d3-a456-426655440000"
kraken_default_runstate: "SYNC"
kraken_default_platform: "vbox"
kraken_default_arch: "amd64"
kraken_nodes:
  - 'nodename': "kr1"
    'id': "{{ 'kr1' | to_uuid }}"
    'arch': "{{ kraken_default_arch }}"
    'platform': "{{ kraken_default_platform }}"
    'parentid': "{{ kraken_parent_id }}"
    'runstate': "{{ kraken_default_runstate }}"
    'extensions':
      'Hypervisor':
        "apiServer": "vbm"
        "name": "kr1"
      'IPv4OverEthernet':
        'ifaces':
          'kraken':
            'name': "eth0"
            'ip': '10.11.12.11'
            'subnet': '255.255.255.0'
            'mac': "aa:bb:cc:00:11:01"
```