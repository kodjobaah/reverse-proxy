#!/bin/bash

sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-01060eb250f68245d.efs.eu-west-2.amazonaws.com:/  /opt/fitnesse
