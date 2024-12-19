CREATE ROUTINE LOAD `example_table_rl` ON `example_table`
COLUMNS TERMINATED BY ',',
COLUMNS (uid, column1, column2, column3)
PROPERTIES
(
  "desired_concurrent_number" = "3",
  "format" = "json",
  "max_error_number" = "0",
  "max_filter_ratio" = "1.0",
  "max_batch_interval" = "10",
  "max_batch_rows" = "2000000",
  "task_consume_second" = "15",
  "task_timeout_second" = "60",
  "max_batch_size" = "2000000",
  "jsonpaths" = "[\"$.uid\", \"$.column1\", \"$.column2\", \"$.column3\"]"
)
FROM KAFKA
(
  "kafka_broker_list" = "{{KAFKA_BROKER_LIST}}",
  "kafka_topic" = "example_table",
  "property.security.protocol" = "{{KAFKA_SECURITY_PROTOCOL}}",
  "property.sasl.mechanism" = "{{KAFKA_SASL_MECHANISM}}",
  "property.sasl.username" = "{{KAFKA_SASL_USERNAME}}",
  "property.sasl.password" = "{{KAFKA_SASL_PASSWORD}}",
  "property.enable.ssl.certificate.verification" = "{{KAFKA_SSL_VERIFY}}",
  "confluent.schema.registry.url" = "{{SCHEMA_REGISTRY_URL}}",
  "property.basic.auth.credentials.source" = "USER_INFO",
  "kafka_partitions" = "{{KAFKA_PARTITIONS}}",
  "property.kafka_default_offsets" = "{{KAFKA_OFFSET}}"
);
