#!/bin/sh

BIN_FOLDER=bin
BINARY_NAME_UNIX=run.sh
ENTRY_POINT_UNIX=main.sh

#bash-build:
	mkdir -p $BIN_FOLDER
	cp -r src/* $BIN_FOLDER
	mv $BIN_FOLDER/$ENTRY_POINT_UNIX $BIN_FOLDER/$BINARY_NAME_UNIX
	chmod +x $BIN_FOLDER/$BINARY_NAME_UNIX

#bat-build:

#docker:
