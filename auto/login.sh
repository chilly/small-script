#!/bin/bash
# write one password each line
# this script is used for ftp login.
hostname=XX.com
username=myName
passwordTxt=passwordTxt.txt
for i in `cat ${passwordTxt}`; do
	set timeout 10
	expect << FTP
	spawn ftp $hostname
	expect "Name"
	send "${username}\r"
	expect "Password"
	send "$i\r"
	expect {
		"Login success" {
			send "bye\r"
			exit 0
		}
		"Login failed" {send "bye\r"}
	}

FTP
	echo "\nsend $i with name ${username}, done.\n"
done
	
