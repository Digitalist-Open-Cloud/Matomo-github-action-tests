; <?php exit; ?> DO NOT REMOVE THIS LINE
; This configuration is used for automatic integration
; tests on GitHub Action. Do not use this in production.

[database]
host = 127.0.0.1
username = root
password =
dbname = matomo_tests
adapter = PDO_MYSQL
schema = Mysql
; no table prefix for tests on GitHub
tables_prefix =
;charset = utf8

[tests]
request_uri = "/"
enable_logging = 1

[database_tests]
host = 127.0.0.1
username = root
password =
dbname = matomo_tests
adapter = PDO_MYSQL
schema = Mysql
; no table prefix for tests on GitHub
tables_prefix =

[log]
log_writers[] = file
log_level = info

; leave this empty here
[General]