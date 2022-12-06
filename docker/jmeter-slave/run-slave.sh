# get host IP address
IP=`ifconfig | awk -F':' '/inet addr/&&!/127.0.0.1/{split($2,_," ");print _[1]}'`
SLAVE_IP_STRING=`getent ahostsv4 ${SLAVE_SVC_NAME} |awk '!($1 in a){a[$1];printf "%s%s",t,$1; t=","}'`

# get index of this slave
SLAVE_INDEX=`echo ${SLAVE_IP_STRING} | awk -F',' '{for(i=1;i<=NF;i++)if($i=="'${IP}'")print i}'`
