#define N 3

#ifndef SEMPAPHORE_LOCK

typedef mutex_lock_t {
	int TODO;
};

#define mutex_lock_init(l) printf("mutex_lock_init()\n")

#define mutex_lock_acquire(l) printf("mutex_lock_acquire()\n")
#define mutex_lock_release(l) printf("mutex_lock_release()\n")

#endif

#ifndef QUEUE_NONDETERMINISTIC

typedef queue_t {
	chan channel = [N] of { int };
};

#define queue_is_empty(queue) empty(queue.channel)
#define queue_is_not_empty(queue) nempty(queue.channel)

#define queue_pop(queue, x) queue.channel ? x
#define queue_push(queue, x) queue.channel ! x
#define queue_fifo_push(queue, x) queue.channel ! x

#define queue_length(queue) len(queue.channel)

#endif

typedef group_mutual_exclusion_shared_t {
	mutex_lock_t lock;
	int session;
	int num; //TODO: rename to number in critical section
	queue_t queue;
	bool wait[N];
	int need[N];
};

inline group_mutual_exclusion_shared_init(gmes) {
	mutex_lock_init(gmes.lock);
	gmes.session = 1;
	gmes.num = 0;
	//TODO: queue init
	//wait array init
	//need array init
}


group_mutual_exclusion_shared_t shared;

active [N] proctype GroupMutualExclusionProcess() {
	int chosen_group;
	int queue_iterator;
	int temp_pid;
	bool temp_bool_as_workaround;
	int temp_for_steps;

	printf("New process pid:%d\n", _pid);

	//TODO: local section
	//TODO: wybor grupy : chosen_group

	shared.wait[_pid] = false;
	shared.need[_pid] = chosen_group;

	mutex_lock_acquire(shared.lock);

	temp_bool_as_workaround = queue_is_empty(shared.queue);

	if
	:: (shared.session == chosen_group) && temp_bool_as_workaround ->
		shared.num = shared.num + 1;
	:: (shared.session != chosen_group) && (shared.num == 0) ->
		shared.session = chosen_group;
		shared.num = 1;
	:: else ->
		shared.wait[_pid] = false;
		queue_push(shared.queue, _pid); //TODO: insert shared.queue _pid
	fi;

	mutex_lock_release(shared.lock);

	(!shared.wait[_pid]); // WAIT

	//TODO: CRITICAL SECTION IS HERE!

	mutex_lock_acquire(shared.lock);
	shared.num = shared.num - 1;

	temp_bool_as_workaround = queue_is_not_empty(shared.queue);
	temp_for_steps = queue_length(shared.queue);

	if
	:: temp_bool_as_workaround && shared.num == 0 ->
		for (queue_iterator : 1 .. temp_for_steps) {
			queue_pop(shared.queue, temp_pid);
			if
			:: 1 == queue_iterator ->
				shared.session = shared.need[temp_pid];
			:: else ->
				skip;
			fi;

			if
			:: shared.session == shared.need[temp_pid] ->
				shared.num = shared.num + 1;
				shared.wait[temp_pid] = false;
			:: else ->
				queue_fifo_push(shared.queue, temp_pid);
			fi;
		}
	:: else ->
		skip;
	fi;

	mutex_lock_release(shared.lock);
}

//ltl liveness { []
//(GroupMutualExclusionProcess[0]@want -> <>Process[0]@cs)
//}
