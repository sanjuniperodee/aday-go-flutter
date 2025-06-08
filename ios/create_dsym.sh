#!/bin/bash

echo "Generating dSYM files for Mapbox frameworks..."

# Find all Mapbox frameworks in the project
find "${PODS_ROOT}" -name "Mapbox*.framework" -type d | while read -r FRAMEWORK; do
  FRAMEWORK_EXECUTABLE_NAME=$(defaults read "$FRAMEWORK/Info.plist" CFBundleExecutable)
  FRAMEWORK_EXECUTABLE_PATH="$FRAMEWORK/$FRAMEWORK_EXECUTABLE_NAME"
  
  echo "Generating dSYM for $FRAMEWORK_EXECUTABLE_NAME"
  
  # Create dSYM file
  xcrun dsymutil -o "${BUILT_PRODUCTS_DIR}/${FRAMEWORK_EXECUTABLE_NAME}.framework.dSYM" "$FRAMEWORK_EXECUTABLE_PATH"
  
  # Copy the dSYM to the archive's dSYMs folder
  if [ -n "$DWARF_DSYM_FOLDER_PATH" ]; then
    cp -R "${BUILT_PRODUCTS_DIR}/${FRAMEWORK_EXECUTABLE_NAME}.framework.dSYM" "$DWARF_DSYM_FOLDER_PATH"
  fi
done

echo "dSYM generation complete" 