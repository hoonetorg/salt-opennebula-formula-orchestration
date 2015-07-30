{% set opennebula_controllers = salt['pillar.get']("opennebula:members:controllers" , False)|sort -%}
{% set opennebula_compute_nodes = salt['pillar.get']("opennebula:members:compute_nodes" , False)|sort -%}
{% set opennebula_servers = opennebula_controllers + opennebula_compute_nodes -%}

{#
{% if opennebula_servers is defined and opennebula_servers %}

orchestration_opennebula__servers_highstate:
  salt.state:
    - tgt: {{opennebula_servers}}
    - tgt_type: list
    - expect_minions: True
    - highstate: True
    - require_in:
      - salt: orchestration_opennebula__controller_finished
      - salt: orchestration_opennebula__compute_nodes_finished

{% endif %}
#}

{% if opennebula_controllers is defined and opennebula_controllers %}

orchestration_opennebula__install_controller:
  salt.state:
    - tgt: {{opennebula_controllers}}
    - tgt_type: list
    - expect_minions: True
    - sls: opennebula.controller
#    - require:
#      - salt: orchestration_opennebula__servers_highstate
    - require_in:
      - salt: orchestration_opennebula__controller_finished
      - salt: orchestration_opennebula__compute_nodes_finished

{% endif %}

orchestration_opennebula__controller_finished:
  salt.function:
    - tgt: '{{grains['fqdn']}}'
    - expect_minions: True
    - name: cmd.run
    - arg: 
      - "echo \"`date`: opennebula_controllers deploy finished\" >> /var/log/opennebulaorchestrate.log"

{% if opennebula_compute_nodes is defined and opennebula_compute_nodes %}

orchestration_opennebula__install_compute_node:
  salt.state:
    - tgt: {{opennebula_compute_nodes}}
    - tgt_type: list
    - expect_minions: True
    - sls: opennebula.compute_node
    - require:
#      - salt: orchestration_opennebula__servers_highstate
      - salt: orchestration_opennebula__install_controller
      - salt: orchestration_opennebula__controller_finished
    - require_in:
      - salt: orchestration_opennebula__compute_nodes_finished

{% endif %}

orchestration_opennebula__compute_nodes_finished:
  salt.function:
    - tgt: '{{grains['fqdn']}}'
    - expect_minions: True
    - name: cmd.run
    - arg: 
      - "echo \"`date`: opennebula_compute_nodes deploy finished\" >> /var/log/opennebulaorchestrate.log"
    - require:
      - salt: orchestration_opennebula__controller_finished
