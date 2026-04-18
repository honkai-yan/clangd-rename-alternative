cmake_minimum_required(VERSION 3.16)
project(test_game C)

set(CMAKE_EXPORT_COMPILE_COMMANDS on)
set(CMAKE_C_STANDARD 11)

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

add_executable(test_game 
  main.c
  winapi.c
  snake_game.c
)

target_include_directories(test_game PRIVATE lib)

target_link_directories(test_game PRIVATE lib/raylib)

target_link_libraries(test_game PRIVATE raylib.lib Winmm.lib)
