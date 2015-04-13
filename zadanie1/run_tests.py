#!/usr/bin/env python
# -*- coding: UTF-8 -*-

#import socket
#import os
#import re
import subprocess
#import signal
#import time

#spin -DQUEUE_DETERMINISTIC -DLTL_LIVENESS -a group_mutual_exclusion.pml && gcc -O2 -o pan pan.c && ./pan -a -f -m100000
#spin -DQUEUE_NONDETERMINISTIC -DLTL_LIVENESS -g -p -t -T group_mutual_exclusion.pm

class SpinOutputDoctor(object):
	def is_it_a_trail(self, output):
		return output.find("wrote group_mutual_exclusion.pml.trail") != -1
		#return False

def do_it_yourself_command_line(command_args):
	return " ".join(command_args)

def spin_generate(common_args):
	args = ["spin", "-a"] + common_args
	print do_it_yourself_command_line(args)
	process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	(stdoutdata, stderrdata) = process.communicate()
	process.wait()

def pan_verify():
	args = ["./pan", "-a", "-f", "-m100000"]
	process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	(stdoutdata, stderrdata) = process.communicate()
	process.wait()
	return stdoutdata

def pan_compile():
	args = ["gcc", "-O2", "-o", "pan", "pan.c"]
	process = subprocess.Popen(args)
	process.wait()

def check_trail(common_args):
	args = ["spin", "-t", "-T"] + common_args
	process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	(stdoutdata, stderrdata) = process.communicate()
	process.wait()
#	print do_it_yourself_command_line(args)
#	print stdoutdata

def run_that_test():
#	os.unlink(self.pid_file)
#	local_output = open(self.log_debug, 'w')

#	args = ["ls", "-rtla"]
#	process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
#	(stdoutdata, stderrdata) = process.communicate()
#	process.wait()
#	print stdoutdata
	doctor = SpinOutputDoctor()

	queue_type_list = ["QUEUE_DETERMINISTIC", "QUEUE_NONDETERMINISTIC"]
	ltl_list = ["LTL_MUTUAL_EXCLUSION", "LTL_CONCURRENT_ENTERING", "LTL_LIVENESS"]

	for queue_type in queue_type_list:
		for ltl in ltl_list:
			common_args = ["-D" + queue_type, "-D" + ltl, "group_mutual_exclusion.pml"]
			spin_generate(common_args)
			pan_compile()
			verify_results = pan_verify()
			if doctor.is_it_a_trail(verify_results):
				print "TRAIL FAIL"
				#check_trail(common_args)
			else:
				print "OK"

if __name__ == "__main__":
	run_that_test()
