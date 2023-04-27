cmake_minimum_required(VERSION 3.13)

project(BatteryStatus
    VERSION 1.0.0
    DESCRIPTION "This is a demo project"
)

enable_language(C ASM)

set(SOURCES
    main.cpp
)

# Get QT4 CMake package, needed for building all Qt projects
find_package( Qt4 REQUIRED ) 
include( ${QT_USE_FILE} ) 
add_definitions( ${QT_DEFINITIONS} ) 
include_directories( ${CMAKE_BINARY_DIR} )

# Using Qt meta-system (precompiler)
# QT4_ADD_RESOURCES( RES_SOURCES ${RESOURCES} ) QT4_WRAP_UI( UI_HEADERS ${UIS} ) QT4_WRAP_CPP( MOC_SRCS ${MOC_HEADERS} )

# add_executable( PROJECT_NAME ${SOURCES} ${MOC_SRCS} ${RES_SOURCES} ${UI_HEADERS} )
add_executable( PROJECT_NAME ${SOURCES} )

target_link_libraries( PROJECT_NAME ${QT_LIBRARIES} )

if(WIN32) 
    # Check if we are on Windows 
    if(MSVC) 
        # Check if we are using the Visual Studio compiler 
        set_target_properties(${PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE YES LINK_FLAGS "/ENTRY:mainCRTStartup" ) 
    elseif(CMAKE_COMPILER_IS_GNUCXX) 
        # SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mwindows") # Not tested 
    else() 
        message(SEND_ERROR "You are using an unsupported Windows compiler! (Not MSVC or GCC)") 
    endif(MSVC) 
elseif(APPLE) 
    set_target_properties(${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE YES ) 
elseif(UNIX) 
    # Nothing special required 
else() 
    message(SEND_ERROR "You are on an unsupported platform! (Not Win32, Mac OS X or Unix)")
endif(WIN32)

