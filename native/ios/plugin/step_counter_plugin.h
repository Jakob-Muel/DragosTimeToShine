#pragma once

#include "core/object/class_db.h"

class StepCounterPlugin : public Object {
	GDCLASS(StepCounterPlugin, Object);

	static StepCounterPlugin *singleton;
	static void _bind_methods();

	void emit_permission_result(bool p_granted);
	void emit_steps_result(int64_t p_start_unix, int64_t p_steps);
	void emit_step_error(const String &p_message);

public:
	static StepCounterPlugin *get_singleton();

	bool has_permission() const;
	void request_permission();
	void query_steps_since(int64_t p_start_unix);

	StepCounterPlugin();
	~StepCounterPlugin();
};
