import sys
import os
from collections import defaultdict

class Filter:
  def __init__(self, input_file, output_file, threshold, entity):
    self.input_file_name = input_file
    if os.path.isfile(output_file) and os.path.samefile(output_file, input_file):
      print("Input and output file is the same, exiting.")
      sys.exit(2)
    self.output_file_name = output_file
    self.threshold = threshold
    if entity=="user" :
      self.entity_column = 1
    else : #item
      self.entity_column = 2

  def run(self):
    self.num_of_occ = defaultdict(lambda: 0)
    self.count_entity_occurrences()
    self.write_out_filtered_timeline()

  def count_entity_occurrences(self):
    input_file = open(self.input_file_name, "r")
    for line in input_file:
      fields=line.split(" ")
      if(len(fields)<3):
        continue
      entity = int(fields[self.entity_column])
      self.num_of_occ[entity]+=1

  def write_out_filtered_timeline(self):
    output_file = open(self.output_file_name, "w")
    input_file = open(self.input_file_name, "r")
    for line in input_file:
      fields=line.split(" ")
      if(len(fields)<3):
        continue
      entity = int(fields[self.entity_column])
      if(self.num_of_occ[entity]>=self.threshold):
        output_file.write(line)

def main():
  if len(sys.argv)<4:
    print("usage: python n_filter.py input_file output_file n (user|item)")
    return
  occurrence_filter=Filter(sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4])
  occurrence_filter.run()

if __name__ == "__main__":
  main()
      
