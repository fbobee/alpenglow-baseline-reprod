import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import itertools
from alpenglow.evaluation import *
from alpenglow.experiments import *
import copy
import os
import json
import sys
import datetime
import subprocess
import time

if len(sys.argv)<2:
  print("usage: python experiment.py parameters.json")
  exit(1)
json_file = sys.argv[1] 

def compute_parameter_combinations(parameters):
  for key,parameter in parameters.items():
    if not isinstance(parameter,list) :
      parameters[key] = [ parameter ]
  parameter_names = parameters.keys()
  parameter_value_lists = parameters.values()
  parameter_combination_tuples = itertools.product(*parameter_value_lists)
  combinations = []
  for combination in parameter_combination_tuples :
    combinations.append(dict(zip(parameter_names,combination)))
  return combinations

output_path_parameters = {"base_out_file_name"} #handle relative path (OUTPUT_DIR), create dir
long_parameters = {"base_out_file_name", "base_in_file_name"} #do not include in experiment dir
    
with open(json_file) as f:
  param_data = json.load(f)

parameters=param_data["parameters"]
parameter_combinations = compute_parameter_combinations(parameters)

path = param_data["path"]
data = path["data_dir"]+"/"+path["dataset"]+"/baseline_uniformed/"+path["data_variant"]

param_name_list = list(parameters.keys())
for key in long_parameters :
  if key in param_name_list: 
    param_name_list.remove(key)
output_root_dir = path["output_dir"]+"/"+path["dataset"]+"/"+path["data_variant"]+"/"+param_data["experiment_type"]+"/"+"-".join(sorted(param_name_list))+"/experiments/"

experiment_base = globals()[param_data["experiment_type"]](
    top_k=100,
)

evaluators = {"dcg":"DcgScore", "rr":"RrScore"}


for parameter_combination in parameter_combinations :
  parametered_experiment = copy.deepcopy(experiment_base)
  out_dir=output_root_dir+"experiment"
  for key in sorted(parameter_combination) :
    if key not in output_path_parameters :
      parametered_experiment.set_parameter(key, parameter_combination[key])
    if key not in long_parameters :
      out_dir += "-" + key + "_" + str(parameter_combination[key])
  if not os.path.exists(out_dir) :
    os.makedirs(out_dir)
  elif not os.path.isdir(out_dir) or os.listdir(out_dir) :
    print("Output dir '"+out_dir+"' exists, but is not an empty directory, skipping the parameter combination.")
    continue
  log_file = open(out_dir+"/log", "a")
  log_file.write(str(datetime.datetime.now())+"\n")
  log_file.write("input_file: "+json_file+"\n")
  log_file.write("out_dir: "+out_dir+"\n")
  log_file.write("sys.prefix: "+sys.prefix+"\n")
  script_dir = "/".join(sys.argv[0].split("/")[:-1])
  #git_revision_process = subprocess.run(["git","-C",script_dir,"rev-parse","HEAD"], universal_newlines=True, stdout=subprocess.PIPE)
  #log_file.write("experiment.py git revision: "+git_revision_process.stdout)
  with open(out_dir+"/pid", "w") as f:
    f.write(str(os.getpid()))
  with open(out_dir+"/running", "w") as f:
    f.write("running")
  experiment_parameters = param_data.copy()
  experiment_parameters["parameters"] = parameter_combination
  with open(out_dir+"/parameters.json", "w") as f:
    json.dump(experiment_parameters, f, indent=2)
  for key in output_path_parameters :
    if key in parameter_combination :
      parameter_combination[key]=parameter_combination[key].replace("OUTPUT_DIR", out_dir)
      parametered_experiment.set_parameter(key, parameter_combination[key])
      model_out_dir ="/".join(parameter_combination[key].split("/")[:-1])
      if not os.path.exists(model_out_dir) :
        os.makedirs(model_out_dir)
  if param_data["save_output"] :
    parametered_experiment.set_parameter("out_file", out_dir+"/output_old_style")

  log_file.write("running...")
  print("Writing output into "+out_dir)
  start_time = time.clock()
  my_results = parametered_experiment.run(data, exclude_known=True, experimentType="online_id_noeval", verbose=True, shuffle_same_time=False)
  end_time = time.clock()
  log_file.write(" ok.\n")
  log_file.write("running time of the experiment: "+str(end_time-start_time)+"\n\n")

  my_results['days'] = (my_results['time']-my_results['time'].min())/86400

  for eval_key, eval_class_name in evaluators.items() :
    evaluator = globals()[eval_class_name]
    my_results[eval_key] = evaluator(my_results)
    my_results[eval_key+"_cumulative_avg"] = my_results[eval_key].fillna(0).expanding().mean()
    daily_avg = my_results[eval_key].groupby(my_results['days']).mean()
    daily_avg.to_csv(out_dir+"/daily_avg_"+eval_key, sep=" ", float_format='%.3f')
    plt.plot(daily_avg, label=eval_key)
    plt.savefig(out_dir+"/"+eval_key+".pdf", format="pdf")
    plt.close()
    cumulative_avg = my_results[eval_key+"_cumulative_avg"].groupby(my_results['days']).mean()
    plt.plot(cumulative_avg, label=eval_key)
    plt.savefig(out_dir+"/cumulative_avg_"+eval_key+".pdf", format="pdf")
    plt.close()
  my_results.to_csv(out_dir+"/output", sep=" ", float_format='%.5f')
  os.remove(out_dir+"/running")
