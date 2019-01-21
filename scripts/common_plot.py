import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import sys
import os

if len(sys.argv)<3 :
  print("Usage info:")
  print("use through common_plot shell script")
  print("example usage:")
  print("python scripts/common_plot.py mlens_100k sameshuf PopularityExperiment:results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output FactorExperiment:results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output TransitionProbabilityExperiment:results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output")
  exit(-1)

dataset = sys.argv[1]
variant = sys.argv[2]

models = []
for result in sys.argv[3:] :
  L = result.split(":")
  if len(L)<2 or len(L[0])==0 or len(L[1])==0 :
    print("Skipping bad parameter: "+result)
    continue
  model = L[0]
  models.append(model)
  path = L[1]
  output = pd.read_csv(path, sep=" ")
  filtering_proportion=len(output)//1000
  filtered_output=output.iloc[::filtering_proportion] #TODO add last line too
  plt.plot(filtered_output['days'],filtered_output['dcg_cumulative_avg'], label=model)
plt.legend()
output_dir = "results/"+dataset+"/scrobbles-"+variant+"-first-5_item_filter-recoded/common_results"
if not os.path.exists(output_dir) :
  os.makedirs(output_dir)
models.sort()
model_names="-".join(models)
output_file_name=output_dir+"/cumulative_dcg-"+model_names+".pdf"
plt.savefig(output_file_name, format="pdf")
print("Plot is saved into "+output_file_name)
