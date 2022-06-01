if [ "$AUTO_RUN" = "true" ]; then
  while true ; do
    echo "Auto-running tests."
    until [ $(find ${TESTS_DIR}/ -type f -name *.jmx -maxdepth 1 | wc -l) -ne 0 ]; do
      echo "Waiting for test files to be created in ${TESTS_DIR}..."
      sleep 20
    done
    if [ -z ${SLAVE_IP_STRING} ]; then
    SLAVE_IP_STRING=`getent ahostsv4 ${SLAVE_SVC_NAME} |awk '!($1 in a){a[$1];printf "%s%s",t,$1; t=","}'`
    fi
    echo "Using slaves ${SLAVE_IP_STRING}."
    for file in ${TESTS_DIR}/*.jmx ; do
      echo "Running test file ${file}."
      jmeter -n -t ${file} -Jserver.rmi.ssl.disable=${SSL_DISABLED} -R ${SLAVE_IP_STRING} -j ${TESTS_DIR}/jmeter.log -l ${TESTS_DIR}/jmeter.jtl
      echo "Test file ${file} finished, removing it..."
      rm ${file}
    done
  done
else
  while true ; do
    echo "Wait for manual run."
    sleep 60
  done
fi
