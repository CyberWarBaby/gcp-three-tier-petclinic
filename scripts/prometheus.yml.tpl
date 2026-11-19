global:
  scrape_interval: 15s

scrape_configs:
  - job_name: app
    metrics_path: /petclinic/actuator/prometheus
    gce_sd_configs:
      - project: ${project}
        zone: europe-west1-b
        port: 9966
      - project: ${project}
        zone: europe-west1-c
        port: 9966
      - project: ${project}
        zone: europe-west1-d
        port: 9966
    relabel_configs:
      - source_labels: [__meta_gce_tags]
        regex: '.*,app,.*'
        action: keep
      - source_labels: [__meta_gce_instance_name]
        target_label: instance
      - target_label: application
        replacement: petclinic

  - job_name: node
    gce_sd_configs:
      - project: ${project}
        zone: europe-west1-b
        port: 9100
      - project: ${project}
        zone: europe-west1-c
        port: 9100
      - project: ${project}
        zone: europe-west1-d
        port: 9100
    relabel_configs:
      - source_labels: [__meta_gce_tags]
        regex: '.*,(app|web),.*'
        action: keep
      - source_labels: [__meta_gce_instance_name]
        target_label: instance