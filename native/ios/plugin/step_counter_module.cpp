#include "step_counter_module.h"

#include "core/config/engine.h"
#include "step_counter_plugin.h"

static StepCounterPlugin *step_counter_plugin = nullptr;

void register_step_counter_types() {
	step_counter_plugin = memnew(StepCounterPlugin);
	Engine::get_singleton()->add_singleton(
			Engine::Singleton("StepCounterPlugin", step_counter_plugin));
}

void unregister_step_counter_types() {
	if (step_counter_plugin != nullptr) {
		memdelete(step_counter_plugin);
		step_counter_plugin = nullptr;
	}
}
