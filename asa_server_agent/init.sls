{%- set default_sources = {'module' : 'asa_server_agent', 'defaults' : True, 'pillar' : True, 'grains' : ['os_family']} %}
{%- from "./defaults/load_config.jinja" import config as asa_server_agent with context %}

{% if asa_server_agent.use is defined %}

{% if asa_server_agent.use | to_bool %}


{% set os_family = grains['os_family']|lower %}
{% if os_family == 'redhat' %}

GPG_KEY_OktaPAM:
  rpm_.imported_gpg_key:
    - key_path: {{ asa_server_agent.gpgkey }}

{{ asa_server_agent.repo_name }}:
  pkgrepo.managed:
    - name: {{ asa_server_agent.repo_name }}
    - humanname: {{ asa_server_agent.repo_humanname }}
    - baseurl: {{ asa_server_agent.repo_baseurl }}
    - gpgcheck: 1
    - repo_gpgcheck: 1
    - gpgkey: {{ asa_server_agent.gpgkey }}
    - require:
      - GPG_KEY_OktaPAM

{% elif os_family == 'debian' %}

  pkgrepo.managed:
    - name: {{ asa_server_agent.name }}
    - dist: {{ grains['oscodename'] }}
    - comps: {{ asa_server_agent.comps }}
    - file: {{ asa_server_agent.file }}
    - key_url: {{ asa_server_agent.key_url }}
    - refresh_db: True
    - order: 1

{% endif %}

asa_server_agent_service_config_dir:
  file.directory:
    - name: {{ asa_server_agent.config_dir }}
    - makedirs: True

asa_server_agent_conf_file:
  file.managed:
    - name: {{ asa_server_agent.config_dir }}/sftd.yaml
    - source: salt://{{ slspath }}/files/sftd.yaml
    - template: jinja
    - require:
      - file: asa_server_agent_service_config_dir

asa_server_agent_installation:
  pkg.installed:
    - name: {{ asa_server_agent.package_name }}
    - require:
      - pkgrepo: {{ asa_server_agent.repo_name }}

asa_server_agent_service_running:
  service.running:
    - name: {{ asa_server_agent.service_name }}
    - enable: True
    - require:
      - asa_server_agent_installation
    - watch:
      - asa_server_agent_installation
      - asa_server_agent_conf_file
      - asa_server_agent_service_enrollment_token

asa_server_agent_service_enrollment_dir:
  file.directory:
    - name: {{ asa_server_agent.enrollment_dir }}
    - makedirs: True

asa_server_agent_service_enrollment_token:
  cmd.run:
    - name: echo "{{ asa_server_agent.common_config.enrollment_token }}" > {{ asa_server_agent.enrollment_dir }}/enrollment.token
    - creates: {{ asa_server_agent.enrollment_dir }}/device.token
    - require:
      - file: asa_server_agent_service_enrollment_dir
{% else %}

asa_server_agent_service_stopped:
  service.dead:
    - name: {{ asa_server_agent.service_name }}
    - enable: False

asa_server_agent_removal:
  pkg.removed:
    - name: {{ asa_server_agent.package_name }}
    - require:
      - asa_server_agent_service_stopped

{% endif %}

{% endif %}
