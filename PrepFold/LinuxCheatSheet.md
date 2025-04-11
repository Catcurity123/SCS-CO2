#### Copy file from local to remote and vice versa
(+) scp <username>@<ip>:<path_to_remote_file> <path_to_local_file>: get a file from remote server to local
==> scp cloud_user@47.129.248.120:/home/cloud_user/CloudSec/initAwsProfile.sh .

(+) scp <path_to_local_file> <username>@<ip>:<path_to_remote_file>: get a file from local to remote
==> scp ./initAwsProfile.sh cloud_user@47.129.248.120:/home/cloud_user/CloudSec/