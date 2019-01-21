import sys
import os.path
import alpenglow

if len(sys.argv) != 3 :
  print("Illegal number of parameters.")
  print("Usage:")
  print(sys.argv[0]+" input_file output_file")
  exit(1)

orig_file_name = sys.argv[1]
filtered_file_name = sys.argv[2]

if not os.path.exists(orig_file_name) :
  print("Input file does not exist.")
  exit(2)

if os.path.exists(filtered_file_name) and os.path.samefile(orig_file_name, filtered_file_name) :
  print("Input and output file is the same.")
  exit(3)

orig_file = open(orig_file_name, "r")
filtered_file = open(filtered_file_name, "w")

known_pairs = set()
for line in orig_file :
  fields = line.split()
  user = fields[1]
  item = fields[2]
  user_item = user+" "+item
  if user_item not in known_pairs :
    known_pairs.add(user_item)
    filtered_file.write(line)
