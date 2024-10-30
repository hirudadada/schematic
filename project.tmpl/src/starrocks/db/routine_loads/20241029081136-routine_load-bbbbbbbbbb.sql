USE schematic;

CREATE ROUTINE LOAD schematic.bbbbbbbbbb ON example_table
COLUMNS TERMINATED BY ',',
COLUMNS (uid, column_1, column_2, column_3, column_4)
PROPERTIES
(
  "desired_concurrent_number" = "1",
  "format" = "json",
  "jsonpaths" = "[\"$.uid\", \"$.column1\", \"$.column2\", \"$.column3\", \"$.column4\"]"
)
FROM KAFKA
(
  "kafka_broker_list" = "broker1:9092,broker2:9092,broker3:9092",
  "kafka_topic" = "some_topic",
  "property.security.protocol" = "SASL_SSL",
  "property.sasl.mechanism" = "PLAIN",
  "property.sasl.username" = "sasl_username",
  "property.sasl.password" = "sasl_password",
  "property.enable.ssl.certificate.verification" = "false",
  "confluent.schema.registry.url" = "https://sink_username:sink_password@schema_registry_url",
  "property.basic.auth.credentials.source" = "USER_INFO",
  "kafka_partitions" = "0,1,2",
  "property.kafka_default_offsets" = "OFFSET_BEGINNING"
);
