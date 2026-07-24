import os
from pathlib import Path

def main():
    # Define the target directory
    target_dir = Path("SKSE/Plugins/SkyrimNet/config/actions")
    
    # Ensure the directory exists to avoid errors
    if not target_dir.exists():
        print(f"Error: Directory '{target_dir}' does not exist.")
        return

    # Find all files matching the pattern DOM_*.yaml
    target = "SkyDOM_*.yaml"
    matching_files = list(target_dir.glob(target))
    
    if not matching_files:
        print(f"No files matching '{target}' were found.")
        return

    # Iterate through and rename each file
    for filepath in matching_files:
        # Construct the new filename by prepending "SkyrimNet_"
        new_filename = filepath.name.replace("SkyDOM_","DOMSlave_")
        new_filepath = filepath.with_name(new_filename)
        
        # Rename the file
        filepath.rename(new_filepath)
        print(f"Renamed: {filepath.name} -> {new_filename}")

if __name__ == "__main__":
    main()