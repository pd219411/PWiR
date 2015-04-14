#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import subprocess

class SpinOutputDoctor(object):
	def is_it_a_trail(self, output):
		return output.find("wrote group_mutual_exclusion.pml.trail") != -1

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
	#print do_it_yourself_command_line(args)
	process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	(stdoutdata, stderrdata) = process.communicate()
	process.wait()
	return stdoutdata

def pan_compile():
	args = ["gcc", "-O2", "-o", "pan", "pan.c"]
	#print do_it_yourself_command_line(args)
	process = subprocess.Popen(args)
	process.wait()

def check_trail(common_args):
	args = ["spin", "-t", "-T"] + common_args
	process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	(stdoutdata, stderrdata) = process.communicate()
	process.wait()
	return (do_it_yourself_command_line(args), stdoutdata)

def run_that_test():
	doctor = SpinOutputDoctor()

	problem_list = ["CLASSIC", "RW_PROBLEM"]
	semaphore_type_list = ["SEMAPHORE_JUST_ATOMIC", "SEMAPHORE_WEAK", "SEMAPHORE_STRONG"]
	queue_type_list = ["QUEUE_DETERMINISTIC", "QUEUE_NONDETERMINISTIC"]
	ltl_list = ["LTL_MUTUAL_EXCLUSION", "LTL_CONCURRENT_ENTERING", "LTL_LIVENESS"]

	for problem in problem_list:
		for semaphore_type in semaphore_type_list:
			for queue_type in queue_type_list:
				for ltl in ltl_list:
					common_args = ["-D" + semaphore_type, "-D" + queue_type, "-D" + ltl, "-D" + problem, "group_mutual_exclusion.pml"]
					spin_generate(common_args)
					pan_compile()
					verify_results = pan_verify()
					if doctor.is_it_a_trail(verify_results):
						(command_line, trail_output) = check_trail(common_args)
						print "TRAIL FAIL"
						#print command_line
						#print trail_output
					else:
						print "OK"

if __name__ == "__main__":
	run_that_test()
