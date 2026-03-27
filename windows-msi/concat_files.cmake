# concat_files.cmake — Concatenate multiple files into one
#
# Usage: cmake -DOUTPUT=out.txt "-DINPUTS=a.txt;b.txt;c.txt" -P concat_files.cmake

if(NOT DEFINED OUTPUT OR NOT DEFINED INPUTS)
    message(FATAL_ERROR "OUTPUT and INPUTS must be defined")
endif()

file(WRITE "${OUTPUT}" "")
foreach(_file ${INPUTS})
    file(READ "${_file}" _content)
    file(APPEND "${OUTPUT}" "${_content}")
endforeach()
