qt_add_executable(caelestia-config-tests
    configtest.cpp
)

target_include_directories(caelestia-config-tests PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/../src/Caelestia/Config"
)

target_link_libraries(caelestia-config-tests PRIVATE
    caelestia-config
    Qt6::Qml
    Qt6::Test
)

add_test(NAME caelestia-config-tests COMMAND caelestia-config-tests)
