import sys
import argparse
import re
# Create the parser
parser = argparse.ArgumentParser(description='Parses the wiki.')

# Add arguments
parser.add_argument('-v', '--version', type=str, required=True)
parser.add_argument('-n', '--name', type=str, required=True)
parser.add_argument('-o', '--output', type=str, required=True)
parser.add_argument('source', type=str)
args = parser.parse_args()

with open(args.source) as fin:
    print ("creating",args.output)
    with open(args.output,"w") as fout:
        for line in fin:
            line = re.sub(r"\$source",args.source,line)
            line = re.sub(r"\$version",args.version,line)
            line = re.sub(r"\$name",args.name,line)
            fout.write(line)
