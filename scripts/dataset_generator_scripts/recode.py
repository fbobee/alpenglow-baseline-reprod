################################################################################
# Recode user and item id's in an "online" type recsys input file to start from 1 and use all the numbers.
# Check if user id's start from 1 and use all values:
# cat trainfile | cut -f"2" -d" " | sort -nu | tail -n1
# cat trainfile | cut -f"2" -d" " | sort -nu | wc -l
# should give the same number. The same for the items:
# cat trainfile | cut -f"3" -d" " | sort -nu | tail -n1
# cat trainfile | cut -f"3" -d" " | sort -nu | wc -l

import sys
import os

class Recode:
  def __init__(self, input_file, output_file, user_recode_table_output_file = None, item_recode_table_output_file = None):
    if os.path.isfile(output_file) and os.path.samefile(output_file, input_file):
      print("Input and output file is the same, exiting.")
      sys.exit(2)
    self.input_file = open(input_file, "r")
    self.output_file = open(output_file, "w")
    if user_recode_table_output_file != None and item_recode_table_output_file != None :
      self.user_recode_table = open(user_recode_table_output_file, "w")
      self.item_recode_table = open(item_recode_table_output_file, "w")
      self.write_out_tables = True
    else:
      self.write_out_tables = False

  def run(self):
    users={}
    items={}
    for line in self.input_file:
      fields=line.split(" ")
      old_user=int(fields[1])
      old_item=int(fields[2])
      #find the new id in the hashmap
      if not old_user in users:
        #create new if necessary
        users[old_user]=len(users)+1
      if not old_item in items:
        items[old_item]=len(items)+1
      #write new line into the output file
      self.output_file.write(fields[0])
      self.output_file.write(" "+str(users[old_user]))
      self.output_file.write(" "+str(items[old_item]))
      for i in range(3,len(fields)):
        self.output_file.write(" "+fields[i])
    if self.write_out_tables :
      self.user_recode_table.write("user recoded_user\n")
      for key, user in users.items():
        self.user_recode_table.write(str(key)+" "+str(user)+"\n")
      self.item_recode_table.write("item recoded_item\n")
      for key, item in items.items():
        self.item_recode_table.write(str(key)+" "+str(item)+"\n")

def main():
  if len(sys.argv)<3:
    print("usage: python recode.py input_file output_file [user_recode_table_output_file item_recode_table_output_file]")
    print("can handle online, online_id formats and any space separated format where user and item are the 2nd and 3rd colums")
    print("be careful, this program overwrites files without asking")
    return
  if len(sys.argv)>=5:
    recode=Recode(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
  if len(sys.argv)==3:
    recode=Recode(sys.argv[1], sys.argv[2])
  recode.run()

if __name__ == "__main__":
  main()
      
