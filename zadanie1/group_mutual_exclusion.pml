#define N 3

typedef mutex_lock_t {
	int TODO;
};

inline mutex_lock_init(l) {
	printf("mutex_lock_init()\n");
}

inline mutex_lock_acquire(l) {
	printf("mutex_lock_acquire()\n");
}

inline mutex_lock_release(l) {
	printf("mutex_lock_release()\n");
}

typedef queue_t {
	bool data;
};

#define queue_is_empty(queue) queue.data

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

	//TODO: local section
	//TODO: wybor grupy : chosen_group

	shared.wait[_pid] = false;
	shared.need[_pid] = chosen_group;

	mutex_lock_acquire(shared.lock);

	if
	:: (shared.session == chosen_group) && (queue_is_empty(shared.queue)) ->
		shared.num = shared.num + 1;
	:: (shared.session != chosen_group) && (shared.num == 0) ->
		shared.session = chosen_group;
		shared.num = 1;
	:: else ->
		shared.wait[_pid] = false;
		//TODO: insert shared.queue _pid
	fi;

	mutex_lock_release(shared.lock);

	//TODO: while (shared.wait[pid_]) { ; }

	//TODO: CRITICAL SECTION IS HERE!

	mutex_lock_acquire(shared.lock);
	shared.num = shared.num - 1;

	if
	:: (!queue_is_empty(shared.queue)) && shared.num == 0 ->
		skip;
	fi;

	/*
	if (not is_empty(shared.queue) and shared.num == 0) {
		//TODO: shared.session = shared.need[shared.queue.element()];
		for (each each process in shared.queue) {
			if (Need[process] == shared.session) {
				//TODO: remove from shared.queue
				shared.num = shared.num + 1;
				shared.wait[process] = False;
			}
		}
	}
	*/

	mutex_lock_release(shared.lock);
}
