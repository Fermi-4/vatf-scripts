#!/bin/sh

# Test to validate that a unique key is used to encrypt/decrypt secure data
# The test tries to decrypt files encrypted by another board and checks that
# the files can't be decrypted.

TESTFILES_MOUNT='/mnt/gtautoftp'
TESTFILES_NFS_ROOT='10.218.103.34:/volume1/tftpboot/anonymous'
TESTFILES_DIR="${TESTFILES_MOUNT}/linux/lcpd/test_files/secure_storage"
TESTFILE_NAME="0"
TESTFILES_DBFILE="dirf.db"
LOCAL_DIR="/data/tee/"
SECURE_FILE_NAME="hello"
SECURE_FILE_CONTENT="0123456789 hello from secure storage world"
arch=$(uname -m)
SECURE_FILE_EXECUTABLE_PREFIX="secure_hello_world"
SECURE_FILE_EXECUTABLE=${SECURE_FILE_EXECUTABLE_PREFIX}_${arch}

die() {
	echo "ERROR: $*"
	exit 1
}

copy_remote_files() {
	echo "Copying files from ${TESTFILES_DIR}/$1"
	cp -f ${TESTFILES_DIR}/$1/${TESTFILE_NAME} ${LOCAL_DIR} || die "Could not copy files from ${TESTFILES_DIR}/$1"
	cp -f ${TESTFILES_DIR}/$1/${TESTFILES_DBFILE} ${LOCAL_DIR} || die "Could not copy files from ${TESTFILES_DIR}/$1"
}

ls ${TESTFILES_MOUNT} || mkdir ${TESTFILES_MOUNT} || die "could not mkdir ${TESTFILES_MOUNT}"
ls ${TESTFILES_DIR} || mount -t nfs -o nfsvers=3,intr,hard,timeo=14,rsize=8192,wsize=8192 ${TESTFILES_NFS_ROOT} ${TESTFILES_MOUNT} || die "could not mount ${TESTFILES_MOUNT}"

mac=$(cat /sys/class/net/eth0/address)
if [ -z ${mac} ]; then
	die "Could not determine mac address to copy files to unique destination"
fi

if [ -f ${TESTFILES_DIR}/${mac}/${TESTFILE_NAME} -a -f ${TESTFILES_DIR}/${mac}/${TESTFILES_DBFILE} ]; then
	copy_remote_files $mac
else
	ls ${LOCAL_DIR}${TESTFILE_NAME} && (rm ${LOCAL_DIR}${TESTFILE_NAME}; rm ${LOCAL_DIR}${TESTFILES_DBFILE})
	echo "Creating new secure file"
	./${SECURE_FILE_EXECUTABLE} -c -n ${SECURE_FILE_NAME} -d "${SECURE_FILE_CONTENT}" || die "Could not create secure files"
	echo "Copying new files to ${TESTFILES_DIR}/${mac}"
	mkdir ${TESTFILES_DIR}/${mac}/
	cp -f ${LOCAL_DIR}${TESTFILE_NAME}  ${TESTFILES_DIR}/${mac}/
	cp -f ${LOCAL_DIR}${TESTFILES_DBFILE} ${TESTFILES_DIR}/${mac}/
fi

echo "Reading local file"
./${SECURE_FILE_EXECUTABLE} -r 50 -n ${SECURE_FILE_NAME} | grep "${SECURE_FILE_CONTENT}" || die "Unexpected secure file content"

echo "Checking other DUT file can not be decrypted"
secure_hosts=$(ls ${TESTFILES_DIR} | wc -l)
if [ $secure_hosts -lt 2 ]; then
	echo "WARNING: Could not validate decryption of another host's secure file"
	exit 0
fi
other_mac=$(ls ${TESTFILES_DIR} | grep -v ${mac} | head -n 1)
copy_remote_files $other_mac
echo "Trying to read secure file from another host"
./${SECURE_FILE_EXECUTABLE} -r 50 -n ${SECURE_FILE_NAME} | grep  "${SECURE_FILE_CONTENT}" && die "Able to read secure file from another host"

echo "Done. All checks passed!!!"
exit 0