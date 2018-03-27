* GLOBAL:
    ENABLED                 =   true
    TO_FILE                 =   true
    TO_STANDARD_OUTPUT      =   false
    FORMAT                  =   "%level|%datetime{%Y-%M-%d %H:%m:%s:%g}|%msg"
    FILENAME                =   "${OUTPUT_LOG_FILE_PATH_TPL}/log_%datetime{%Y%M%d%H}.log"
    MILLISECONDS_WIDTH      =   3
    PERFORMANCE_TRACKING    =   false
    MAX_LOG_FILE_SIZE       =   209715200 ## 200MB - Comment starts with two hashes (##)
    LOG_FLUSH_THRESHOLD     =   100  ## Flush after every 100 logs

* TRACE:
    FILENAME                =   "${OUTPUT_LOG_FILE_PATH_TPL}/trace_log_%datetime{%Y%M%d%H}.log"
    ENABLED                 =   true

* DEBUG:
    FILENAME                =   "${OUTPUT_LOG_FILE_PATH_TPL}/debug_log_%datetime{%Y%M%d%H}.log"
    ENABLED                 =   true

* FATAL:
    ENABLED                 =   false

* ERROR:
    FILENAME                =   "${OUTPUT_LOG_FILE_PATH_TPL}/error_log_%datetime{%Y%M%d%H}.log"
    ENABLED                 =   true

* WARNING:
     FILENAME                =   "${OUTPUT_LOG_FILE_PATH_TPL}/warning_log_%datetime{%Y%M%d%H}.log"
     ENABLED                 =   true

* INFO:
    FILENAME                =   "${OUTPUT_LOG_FILE_PATH_TPL}/info_log_%datetime{%Y%M%d%H}.log"
    ENABLED                 =   true

* VERBOSE:
    ENABLED                 =   false
