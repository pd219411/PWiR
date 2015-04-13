#define N 3

#ifndef SEMPAPHORE_LOCK

typedef mutex_lock_t {
	int TODO;
};

#define mutex_lock_init(l) printf("mutex_lock_init()\n")

#define Acquire(l) atomic {
#define Release(l) }


#endif


//-------------------- queue

#ifdef QUEUE_DETERMINISTIC

typedef queue_t {
	chan channel = [N] of { int };
};

#define queue_is_empty(queue) empty(queue.channel)
#define queue_is_not_empty(queue) nempty(queue.channel)

#define queue_pop(queue, x) queue.channel ? x

#define queue_fifo_push(queue, x) queue.channel ! x

#define queue_length(queue) len(queue.channel)

#define queue_push(queue, x) queue.channel ! x

#endif

#ifdef QUEUE_NONDETERMINISTIC

typedef queue_t {
	chan channel_x = [N] of { int };
	chan channel_o = [N] of { int };
};

#define queue_is_empty(queue) (empty(queue.channel_x) && empty(queue.channel_o))
#define queue_is_not_empty(queue) (nempty(queue.channel_x) || nempty(queue.channel_o))


#define queue_pop(queue, x) \
if \
:: queue.channel_x ? x \
:: empty(queue.channel_x) -> \
	queue.channel_o ? x; \
fi

#define queue_fifo_push(queue, x) queue.channel_o ! x

#define queue_length(queue) (len(queue.channel_x) + len(queue.channel_o))

#define queue_push(queue, x) \
if \
:: true -> \
	queue.channel_x ! x; \
:: true -> \
	queue.channel_o ! x; \
fi

#endif
////////////////////////////////


#define group_selection(out_group, pid) out_group = pid

typedef group_mutual_exclusion_shared_t {
	mutex_lock_t lock;
	int session;
	int num; //TODO: rename to number in critical section
	queue_t queue;
	bool wait[N];
	int chosen_group[N];
};

inline group_mutual_exclusion_shared_init(gmes) {
	mutex_lock_init(gmes.lock);
	gmes.session = 1;
	gmes.num = 0;
	//TODO: queue init
	//wait array init
	//chosen group array init
}


group_mutual_exclusion_shared_t shared;

proctype GroupMutualExclusionProcess() {
	int queue_iterator;
	int temp_pid;
	bool temp_bool_as_workaround;
	int temp_for_steps;
	int my_pid = _pid - 1;
	group_selection(shared.chosen_group[my_pid], my_pid);
	printf("session pid group  %d  %d %d    NEW PROCESS\n", shared.session, my_pid, shared.chosen_group[my_pid]);

	do
	:: true ->
private:
	skip;

	shared.wait[my_pid] = false;

	Acquire(shared.lock)
	temp_bool_as_workaround = queue_is_empty(shared.queue);

	if
	:: (shared.session == shared.chosen_group[my_pid]) && temp_bool_as_workaround ->
		printf("session pid group  %d  %d %d    PRE no waiting, %d other already inside\n", shared.session, my_pid, shared.chosen_group[my_pid], shared.num);
		shared.num = shared.num + 1;
	:: (shared.session != shared.chosen_group[my_pid]) && (shared.num == 0) ->
		printf("session pid group  %d  %d %d    PRE changes session from %d to %d\n", shared.session, my_pid, shared.chosen_group[my_pid], shared.session, shared.chosen_group[my_pid]);
		shared.session = shared.chosen_group[my_pid];
		shared.num = 1;
	:: else ->
		printf("session pid group  %d  %d %d    PRE waits\n", shared.session, my_pid, shared.chosen_group[my_pid]);
		shared.wait[my_pid] = true;
		queue_push(shared.queue, my_pid);
	fi;

	Release(shared.lock)

	(!shared.wait[my_pid]); // WAIT

critical:
	printf("session pid group  %d  %d %d    ENTERS!\n", shared.session, my_pid, shared.chosen_group[my_pid]);

	Acquire(shared.lock)

	shared.num = shared.num - 1;

	temp_bool_as_workaround = queue_is_not_empty(shared.queue);
	temp_for_steps = queue_length(shared.queue);

	if
	:: temp_bool_as_workaround && shared.num == 0 ->
		for (queue_iterator : 1 .. temp_for_steps) {
			queue_pop(shared.queue, temp_pid);
			if
			:: 1 == queue_iterator ->
				shared.session = shared.chosen_group[temp_pid];
			:: else ->
				skip;
			fi;

			if
			:: shared.session == shared.chosen_group[temp_pid] ->
				shared.num = shared.num + 1;
				shared.wait[temp_pid] = false;
				printf("session pid group  %d  %d %d    LEAVES invites process | %d\n", shared.session, my_pid, shared.chosen_group[my_pid], temp_pid);
			:: else ->
				queue_fifo_push(shared.queue, temp_pid);
				printf("session pid group  %d  %d %d    LEAVES encounters      | %d\n", shared.session, my_pid, shared.chosen_group[my_pid], temp_pid);
			fi;
		}
	:: else ->
		printf("session pid group  %d  %d %d    LEAVES\n", shared.session, my_pid, shared.chosen_group[my_pid]);
	fi;

	Release(shared.lock)

	od;
}

init {
	int k = 0;
	group_mutual_exclusion_shared_init(shared);
	atomic {
	do
	:: k < N -> run GroupMutualExclusionProcess(); k++;
	:: else  -> break;
	od
	};
}

#ifdef LTL_MUTUAL_EXCLUSION

ltl mutual_exclusion {
always (
	(GroupMutualExclusionProcess[0]@critical && GroupMutualExclusionProcess[1]@critical)
	implies
	(shared.chosen_group[0] == shared.chosen_group[1])
)
}

#endif

#ifdef LTL_CONCURRENT_ENTERING

ltl concurrent_entering {
always (
	(GroupMutualExclusionProcess[1]@private && GroupMutualExclusionProcess[2]@private)
	implies
	(eventually GroupMutualExclusionProcess[0]@critical)
)
}

#endif

#ifdef LTL_LIVENESS

ltl liveness {
(eventually GroupMutualExclusionProcess[0]@critical) &&
always (
	(GroupMutualExclusionProcess[0]@private implies (eventually GroupMutualExclusionProcess[0]@critical)) &&
	(GroupMutualExclusionProcess[0]@critical implies (eventually GroupMutualExclusionProcess[0]@private))
)
}

#endif
