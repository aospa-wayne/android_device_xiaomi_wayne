#!/bin/bash
#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

if [[ -z "${1}" ]]; then
    file="proprietary-files.txt"
else
    file=${1}
fi

if [[ ! -f ${file} ]]; then
    echo "${file} is not a file"
    exit
fi

# Create a temporary working directory
TMPDIR=$(mktemp -d)

# Ignore the line indicating the source of blobs.
# If the line does not contain "package version" it
# is assumed that the information is not provided.
grep -v "package version" ${file} > ${TMPDIR}/files.txt
grep "package version" ${file} > ${TMPDIR}/extracted_lines.txt
if [[ -s ${TMPDIR}/extracted_lines.txt ]]; then
    cat ${TMPDIR}/extracted_lines.txt >> ${TMPDIR}/sorted_files.txt
    echo "" >> ${TMPDIR}/sorted_files.txt
fi

# Displays the current operating system name
OS=`uname`

# Make all section names unique
if [[ ${OS} = "Darwin" ]]; then
    sed -i "" "s/# .*/&00unique/g" ${TMPDIR}/files.txt
else
    sed -i "s/# .*/&00unique/g" ${TMPDIR}/files.txt
fi

# Get and sort the section
cat ${TMPDIR}/files.txt | grep "# " | sort > ${TMPDIR}/sections.txt

# Write the sorted sections to sorted_files.txt
while read section; do
    echo "${section}" >> ${TMPDIR}/sorted_files.txt
    sed -n "/${section}/,/^$/p" ${TMPDIR}/files.txt | LC_ALL=C sort -u | grep -v "# "* | sed '/^[[:space:]]*$/d' >> ${TMPDIR}/sorted_files.txt
    echo -en '\n' >> ${TMPDIR}/sorted_files.txt
done < ${TMPDIR}/sections.txt

# There is one new line too much
if [[ ${OS} = "Darwin" ]]; then
    sed -i "" -e :a -e '/^\n*$/{$d;N;ba' -e '}' ${TMPDIR}/sorted_files.txt
else
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' ${TMPDIR}/sorted_files.txt
fi

# Revert the unique section names
if [[ ${OS} = "Darwin" ]]; then
    sed -i "" "s/00unique//g" ${TMPDIR}/sorted_files.txt
else
    sed -i "s/00unique//g" ${TMPDIR}/sorted_files.txt
fi

mv ${TMPDIR}/sorted_files.txt ${file}

# Clear the temporary working directory
rm -rf "${TMPDIR}"
