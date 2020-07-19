#!/bin/bash
set -e -o pipefail

script=$1

if [ "$script" = "test" ]
then
  TZ=UTC NODE_ICU_DATA=node_modules/full-icu react-app-rewired test --transformIgnorePatterns 'node_modules/(?!(bank-style|bank-style-react|lodash-es)/)'
elif [ "$script" = "test-ci" ]
then
  tsc && cross-env CI=true TZ=UTC NODE_ICU_DATA=node_modules/full-icu react-app-rewired test --transformIgnorePatterns 'node_modules/(?!(bank-style|bank-style-react|lodash-es)/)' --coverage --detectOpenHandles --coverageReporters=text --coverageReporters=lcov --coverageReporters=cobertura --reporters=default --reporters=jest-junit
elif [ "$script" = "test-ci-generatePacts" ]
then
  tsc && cross-env CI=true TZ=UTC NODE_ICU_DATA=node_modules/full-icu react-app-rewired test src/api --transformIgnorePatterns 'node_modules/(?!(bank-style|bank-style-react|lodash-es)/)'
fi