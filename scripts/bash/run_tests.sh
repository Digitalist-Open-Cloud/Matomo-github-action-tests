#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
SET='\033[0m'


if [[ "${COVERAGE}" != "none" ]]; then
    COVERAGE_OUT='--coverage-text'
else
    COVERAGE_OUT=''
fi

if [ "$COVERAGE_HTML_REPORT" = "true" ]; then
  COVERAGE_HTML_REPORT_OUT='--coverage-html html_report'
else
  COVERAGE_HTML_REPORT_OUT=''
fi

if [ -n "$TEST_SUITE" ]; then
  echo -e "${GREEN}Executing tests in test suite $TEST_SUITE...${SET}"
  if [ -n "$PLUGIN_NAME" ]; then
    echo -e "${GREEN}[ plugin name = $PLUGIN_NAME ]${SET}"
  fi

  if [ "$TEST_SUITE" = "Client" ]; then
    status=0
    if [ -d "tests/angularjs" ]; then
      echo -e "${GREEN}Running angularjs tests${SET}"
      cd tests/angularjs
      npm install
      ./node_modules/karma/bin/karma start karma.conf.js --browsers ChromeHeadless --single-run
      status=$?
      echo "Returned status $status"
      cd ../..
    fi
    echo -e "${GREEN}Running vue tests${SET}"
    npm ci
    npm test
    vuestatus=$?
    echo "Returned status $vuestatus"
    if [ $status -ne 0 ]; then
      exit $status
    fi
    exit $vuestatus
  elif [ "$TEST_SUITE" = "JS" ]; then
    if [ -n "$PLUGIN_NAME" ]; then
      if [ $(php -r "require_once './core/Version.php'; echo (int)version_compare(\Piwik\Version::VERSION, '5.0.0-b1', '<');") -eq 1 ]; then
        ./console tests:run-js --matomo-url='http://localhost' # --plugin option not supported pre matomo 5 versions
      else
        ./console tests:run-js --matomo-url='http://localhost' --plugin=$PLUGIN_NAME
      fi
    else
      ./console tests:run-js --matomo-url='http://localhost'
    fi
  elif [ "$TEST_SUITE" = "UI" ]; then
    if [ -n "$PLUGIN_NAME" ]; then
      ./console tests:run-ui --persist-fixture-data --assume-artifacts --plugin=$PLUGIN_NAME --extra-options="$UITEST_EXTRA_OPTIONS"
    else
      ./console tests:run-ui --store-in-ui-tests-repo --persist-fixture-data --assume-artifacts --core --extra-options="$UITEST_EXTRA_OPTIONS"
    fi
  elif [ "$TEST_SUITE" == "PluginTests" ]; then
    if [ -n "$PLUGIN_NAME" ]; then
      mkdir -p html_report
      echo "html-report: $COVERAGE_HTML_REPORT_OUT, coverage: $COVERAGE_OUT"
      if [ -d "plugins/$PLUGIN_NAME/Test" ]; then
        ./vendor/phpunit/phpunit/phpunit --log-junit phpjunit.xml --configuration ./tests/PHPUnit/phpunit.xml $COVERAGE_OUT $COVERAGE_HTML_REPORT_OUT --testsuite $TEST_SUITE $PHPUNIT_EXTRA_OPTIONS plugins/$PLUGIN_NAME/Test/  | tee phpunit.out
      elif [ -d "plugins/$PLUGIN_NAME/tests" ]; then
        ./vendor/phpunit/phpunit/phpunit --log-junit phpjunit.xml --configuration ./tests/PHPUnit/phpunit.xml $COVERAGE_OUT $COVERAGE_HTML_REPORT_OUT --testsuite $TEST_SUITE $PHPUNIT_EXTRA_OPTIONS plugins/$PLUGIN_NAME/tests/ | tee phpunit.out
      else
        ./vendor/phpunit/phpunit/phpunit --log-junit phpjunit.xml --configuration ./tests/PHPUnit/phpunit.xml $COVERAGE_OUT $COVERAGE_HTML_REPORT_OUT --testsuite $TEST_SUITE --group $PLUGIN_NAME $PHPUNIT_EXTRA_OPTIONS | tee phpunit.out
      fi
    else
      ./vendor/phpunit/phpunit/phpunit --log-junit phpjunit.xml --configuration ./tests/PHPUnit/phpunit.xml $COVERAGE_OUT $COVERAGE_HTML_REPORT_OUT --testsuite $TEST_SUITE $PHPUNIT_EXTRA_OPTIONS | tee phpunit.out
    fi

    exit_code="${PIPESTATUS[0]}"

    if [ "$exit_code" -ne "0" ]; then
      exit $exit_code
    elif grep "No tests executed" phpunit.out; then
      exit 1
    else
      exit 0
    fi
  fi
  else
    echo "No known testing suite defined"
    exit 0
fi
