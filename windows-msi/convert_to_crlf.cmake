# convert_to_crlf.cmake — Copy a file converting line endings to CRLF
#
# Usage: cmake -DINPUT=in.txt -DOUTPUT=out.txt -P convert_to_crlf.cmake

if(NOT DEFINED INPUT OR NOT DEFINED OUTPUT)
    message(FATAL_ERROR "INPUT and OUTPUT must be defined")
endif()

file(READ "${INPUT}" _contents)
string(REPLACE "\r\n" "\n" _contents "${_contents}")
string(REPLACE "\n" "\r\n" _contents "${_contents}")
file(WRITE "${OUTPUT}" "${_contents}")
