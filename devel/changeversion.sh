#!/bin/bash
find . -type f \( ! -name 'Changes' \) -exec perl -pi -e's/0\.2\.3/0.3.1/g' {} \;
