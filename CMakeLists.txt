if(WIN32 AND CMAKE_EXPORT_COMPILE_COMMANDS)
  find_program(POWERSHELL_EXECUTABLE NAMES pwsh powershell REQUIRED)

  execute_process(
    COMMAND "${POWERSHELL_EXECUTABLE}"
            -NoProfile
            -ExecutionPolicy Bypass
            -File "${CMAKE_SOURCE_DIR}/ccc.ps1"
            -Path "${CMAKE_BINARY_DIR}/compile_commands.json"
            -SpawnWatcher
    COMMAND_ERROR_IS_FATAL ANY
  )
endif()
