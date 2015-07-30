{% set opennebulaenvironment = salt['pillar.get']('opennebulaenvironment') -%}
{% set opennebula_controllers = salt['pillar.get']( opennebulaenvironment + ":opennebula:members:controllers" , False)|sort -%}
{% set opennebula_compute_nodes = salt['pillar.get']( opennebulaenvironment + ":opennebula:members:compute_nodes" , False)|sort -%}
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

orchestration_opennebula__install_mariadb:
  salt.state:
    - tgt: {{opennebula_controllers}}
    - tgt_type: list
    - expect_minions: True
    - sls: mysql.server
#    - require:
#      - salt: orchestration_opennebula__servers_highstate
    - require_in:
      - salt: orchestration_opennebula__controller_finished
      - salt: orchestration_opennebula__compute_nodes_finished

orchestration_opennebula__create_database:
  salt.state:
    - tgt: {{opennebula_controllers}}
    - tgt_type: list
    - expect_minions: True
    - sls: mysql.database
    - require:
      - salt: orchestration_opennebula__install_mariadb
    - require_in:
      - salt: orchestration_opennebula__controller_finished
      - salt: orchestration_opennebula__compute_nodes_finished

orchestration_opennebula__db_user_and_grants:
  salt.state:
    - tgt: {{opennebula_controllers}}
    - tgt_type: list
    - expect_minions: True
    - sls: mysql.user
    - require:
      - salt: orchestration_opennebula__create_database
    - require_in:
      - salt: orchestration_opennebula__controller_finished
      - salt: orchestration_opennebula__compute_nodes_finished

orchestration_opennebula__install_controller:
  salt.state:
    - tgt: {{opennebula_controllers}}
    - tgt_type: list
    - expect_minions: True
    - sls: opennebula.controller
    - require:
      - salt: orchestration_opennebula__db_user_and_grants
    - require_in:
      - salt: orchestration_opennebula__controller_finished
      - salt: orchestration_opennebula__compute_nodes_finished

orchestration_opennebula__controller_export_oneadmin_home_via_nfs:
  salt.state:
    - tgt: {{opennebula_controllers}}
    - tgt_type: list
    - expect_minions: True
    - sls: nfs.server
    - require:
      - salt: orchestration_opennebula__install_controller
    - require_in:
      - salt: orchestration_opennebula__controller_finished
      - salt: orchestration_opennebula__compute_nodes_finished

orchestration_opennebula__install_sunstone:
  salt.state:
    - tgt: {{opennebula_controllers}}
    - tgt_type: list
    - expect_minions: True
    - sls: opennebula.sunstone
    - require:
      - salt: orchestration_opennebula__controller_export_oneadmin_home_via_nfs
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

orchestration_opennebula__compute_node_install_nfs_client:
  salt.state:
    - tgt: {{opennebula_compute_nodes}}
    - tgt_type: list
    - expect_minions: True
    - sls: nfs.client
    - require:
#      - salt: orchestration_opennebula__servers_highstate
      - salt: orchestration_opennebula__controller_finished
    - require_in:
      - salt: orchestration_opennebula__compute_nodes_finished

orchestration_opennebula__compute_node_autofs_nfs_mount_oneadmin_home:
  salt.state:
    - tgt: {{opennebula_compute_nodes}}
    - tgt_type: list
    - expect_minions: True
    - sls: autofs
    - require:
#      - salt: orchestration_opennebula__servers_highstate
      - salt: orchestration_opennebula__controller_finished
      - salt: orchestration_opennebula__compute_node_install_nfs_client
    - require_in:
      - salt: orchestration_opennebula__compute_nodes_finished

orchestration_opennebula__install_compute_node:
  salt.state:
    - tgt: {{opennebula_compute_nodes}}
    - tgt_type: list
    - expect_minions: True
    - sls: opennebula.compute_node
    - require:
#      - salt: orchestration_opennebula__servers_highstate
      - salt: orchestration_opennebula__controller_finished
      - salt: orchestration_opennebula__compute_node_autofs_nfs_mount_oneadmin_home
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
