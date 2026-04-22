set(SRC
	main.cpp
	applauncherbackground.cpp
	firstrun.cpp
	gesturefilterarea.cpp
	launcherlocalemanager.cpp
	applauncher.cpp
	notificationsnoozer.cpp)
set(HEADERS
	applauncherbackground.h
	firstrun.h
	gesturefilterarea.h
	launcherlocalemanager.h
	applauncher.h
	notificationsnoozer.h
	preloadhelper.h)

find_package(Qt5QuickCompiler)
if(Qt5QuickCompiler_FOUND)
    qtquick_compiler_add_resources(RESOURCES resources-qml.qrc)
else()
    qt5_add_resources(RESOURCES resources-qml.qrc)
endif()

add_executable(bolide-launcher ${SRC} ${HEADERS} ${RESOURCES})

target_link_libraries(bolide-launcher PRIVATE
	Qt5::Quick
	Qt5::WaylandCompositor
	Qt5::DBus
	Mlite5::Mlite5
	Lipstick::Lipstick
	Timed::Timed)

install(TARGETS bolide-launcher
	DESTINATION ${CMAKE_INSTALL_BINDIR})

install(DIRECTORY watchfaces
	DESTINATION ${CMAKE_INSTALL_DATADIR}/bolide-launcher)
install(DIRECTORY watchfaces-img
	DESTINATION ${CMAKE_INSTALL_DATADIR}/bolide-launcher)
install(DIRECTORY watchfaces-preview
	DESTINATION ${CMAKE_INSTALL_DATADIR}/bolide-launcher)
install(DIRECTORY applauncher
	DESTINATION ${CMAKE_INSTALL_DATADIR}/bolide-launcher)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/wallpapers
	DESTINATION ${CMAKE_INSTALL_DATADIR}/bolide-launcher)
