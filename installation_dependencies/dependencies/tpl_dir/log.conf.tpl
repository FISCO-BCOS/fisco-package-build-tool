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

* FATAL:  
    ENABLED                 =   false
    TO_FILE                 =   false
	
* ERROR:  
    ENABLED                 =   true
    TO_FILE                 =   true     
    TO_STANDARD_OUTPUT      =   true 
	
* WARNING: 
     ENABLED                =   true
     TO_FILE                =   true
	 
* INFO: 
    ENABLED                 =   false
    TO_FILE                 =   false 
      
* DEBUG:  
    ENABLED                 =   false
    TO_FILE                 =   false
      
* TRACE:  
    ENABLED                 =   false
    TO_FILE                 =   false

* VERBOSE:  
    ENABLED                 =   false
    TO_FILE                 =   false
