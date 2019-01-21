import sys
import os.path
import alpenglow

if len(sys.argv) != 5 :
  print("Illegal number of parameters.")
  print("Usage:")
  print(sys.argv[0]+" input_file output_file (complete|complete_online|same_timestamp) random_seed")
  exit(1)

orig_file = sys.argv[1]
shuffled_file = sys.argv[2]
shuffle_mode = sys.argv[3]
random_seed = int(sys.argv[4])

if not os.path.exists(orig_file) :
  print("Input file does not exist.")
  exit(2)

if os.path.exists(shuffled_file) and os.path.samefile(orig_file, shuffled_file) :
  print("Input and output file is the same.")
  exit(3)

if shuffle_mode not in ["complete", "complete_online", "same_timestamp"] :
  print("The third parameter is wrong.")
  print("Usage:")
  print(sys.argv[0]+" input_file output_file (complete|complete_online|same_timestamp)")

c = alpenglow.utils.DataShuffler(
    input_file=orig_file,
    output_file=shuffled_file,
    shuffle_mode=shuffle_mode,
    data_format="online_id_noeval",
    seed=random_seed
)
c.run()
