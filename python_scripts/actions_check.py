# /// script
# dependencies = [
#   "pyyaml",
# ]
# ///

import sys
from pathlib import Path
import yaml

def check_yaml_files():
    # Define the target directory relative to the current working directory
    target_dir = Path("SKSE/Plugins/SkyrimNet/config/actions")
    
    if not target_dir.exists():
        print(f"Error: Target directory '{target_dir}' does not exist.")
        sys.exit(1)
        
    if not target_dir.is_dir():
        print(f"Error: '{target_dir}' is not a directory.")
        sys.exit(1)

    # Find all .yaml and .yml files
    yaml_files = list(target_dir.glob("*.yaml")) + list(target_dir.glob("*.yml"))
    
    if not yaml_files:
        print(f"No YAML files found in {target_dir}")
        sys.exit(0)

    failed_files = 0
    print(f"Checking {len(yaml_files)} YAML file(s) in '{target_dir}'...\n")

    for file_path in yaml_files:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                # safe_load parses the file and blocks code execution exploits
                yaml.safe_load(f)
                
        except yaml.YAMLError as exc:
            failed_files += 1
            print(f"❌ Invalid YAML: {file_path}")
            
            # Extract line and column numbers if available
            if hasattr(exc, 'problem_mark') and exc.problem_mark is not None:
                mark = exc.problem_mark
                # PyYAML lines and columns are 0-indexed, so add 1 for human-readable output
                line_num = mark.line + 1
                col_num = mark.column + 1
                print(f"   ↳ Error at Line {line_num}, Column {col_num}:")
                
                # Clean up the multiline string formatting from PyYAML for better readability
                error_msg = str(exc).split('\n')[0]
                print(f"   ↳ Message: {error_msg}\n")
            else:
                print(f"   ↳ Error: {exc}\n")
                
        except Exception as e:
            failed_files += 1
            print(f"❌ System Error reading {file_path}: {e}\n")

    # Final summary and exit codes
    if failed_files > 0:
        print(f"Validation completed: {failed_files} file(s) failed validation.")
        sys.exit(1)
    else:
        print("✅ All YAML files are valid!")
        sys.exit(0)

if __name__ == "__main__":
    check_yaml_files()