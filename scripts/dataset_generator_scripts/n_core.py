# Compute n-core of a recsys dataset (n-core of the user-item bipartite
# graph, edges are samples). Input file format requirements: space separated,
# 2nd and 3rd fields must be user and item.

import sys
import os.path
from collections import defaultdict

class Core:
  def __init__(self, input_file, output_file, n):
    self.input_file = open(input_file, "r")
    self.output_file = open(output_file, "w")
    self.n = n
    self.m = n

  def __init__(self, input_file, output_file, n, m):
    self.input_file = open(input_file, "r")
    self.output_file = open(output_file, "w")
    self.n = n
    self.m = m

  def run(self):
    self.read_file()
    self.compute_core()
    self.write_file()

  def read_file(self):
    self.samples = []
    linenum = 0
    for line in self.input_file:
      linenum+=1
      if linenum%100000==0:
        print("Read "+str(linenum)+" lines.")
      fields=line.split(" ")
      self.samples.append(fields)

  def compute_core(self):
    stable = False
    while not stable:
      stable = self.filter_once()

  def write_file(self):
    for sample in self.samples:
      self.output_file.write(" ".join(sample))

  def filter_once(self):
    #algorithm: compute user and item frequencies, delete samples having <n
    #occurrences.
    user_freqs = defaultdict(lambda: 0)
    item_freqs = defaultdict(lambda: 0)
    orig_length = len(self.samples)
    linenum=0
    for sample in self.samples:
      linenum+=1
      if linenum%1000000==0:
        print("Processed "+str(linenum)+" samples.")
      user = sample[1]
      item = sample[2]
      user_freqs[user]+=1
      item_freqs[item]+=1
    self.samples = [ sample for sample in self.samples if user_freqs[sample[1]]>=self.n and item_freqs[sample[2]]>=self.m ]
    new_length = len(self.samples)
    print("End of a round, new samplenum is "+str(new_length))
    return orig_length == new_length

def main():
  if len(sys.argv)<4:
    print("usage: python n_core.py input_file output_file n [m]")
    print("n is for user-degree, m is for item-degree, m=n by default")
    return
  if os.path.isfile(sys.argv[2]) and os.path.samefile(sys.argv[1], sys.argv[2]):
    print("Input and output file is the same, exiting.")
    return
  if len(sys.argv)==4:
    core_computer=Core(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[3]))
  else:
    core_computer=Core(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))
  core_computer.run()

if __name__ == "__main__":
  main()
      
