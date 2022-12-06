if [ "$AUTO_RUN" = "true" ]; then
  while true ; do
    echo "Auto-running tests."
    until [ $(find ${TESTS_DIR}/ -type f -name *.jmx -maxdepth 1 | wc -l) -ne 0 ]; do
      echo "Waiting for test files to be created in ${TESTS_DIR}..."
      sleep 20
    done
    SLAVE_IP_STRING=`getent ahostsv4 ${SLAVE_SVC_NAME} |awk '!($1 in a){a[$1];printf "%s%s",t,$1; t=","}'`
    echo "Using slaves ${SLAVE_IP_STRING}."
    for file in ${TESTS_DIR}/*.jmx ; do
      echo "Running test file ${file}."
      # generate filename for results: <testname>-<timestamp>.jtl
      RESULT_FILE=`echo ${file} | sed -e "s/.*\///" -e "s/.jmx/-$(date +%Y%m%d%H%M%S).jtl/"`
      echo "Results will be written to ${RESULT_FILE}."
      # run test
      jmeter -n -t ${file} -Jserver.rmi.ssl.disable=${SSL_DISABLED} -R ${SLAVE_IP_STRING} -l ${TESTS_DIR}/${RESULT_FILE}
      # check exit code of jmeter execution itself, which does NOT include test errors (0=success)
      if [ $? = 0 ]; then
        echo "JMeter executed the test file ${file} successfully - removing it."
        rm ${file}
      else
        echo "JMeter could not execute the test file ${file} - keeping it to retry subsequently."
      fi
    done
  done
else
  while true ; do
    echo "Wait for manual run."
    sleep 60
  done
fi
