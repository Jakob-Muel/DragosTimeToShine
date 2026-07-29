#include "step_counter_plugin.h"

#include <algorithm>
#include <cmath>

#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>

namespace {
static NSString *const AUTHORIZATION_COMPLETED_KEY = @"DragosStepAuthorizationCompleted";
static HKHealthStore *health_store = nil;

static String godot_string(NSString *p_value) {
	if (p_value == nil) {
		return String();
	}
	return String::utf8(p_value.UTF8String);
}
} // namespace

StepCounterPlugin *StepCounterPlugin::singleton = nullptr;

void StepCounterPlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("has_permission"), &StepCounterPlugin::has_permission);
	ClassDB::bind_method(D_METHOD("request_permission"), &StepCounterPlugin::request_permission);
	ClassDB::bind_method(D_METHOD("query_steps_since", "start_unix"), &StepCounterPlugin::query_steps_since);

	ADD_SIGNAL(MethodInfo("permission_result", PropertyInfo(Variant::BOOL, "granted")));
	ADD_SIGNAL(MethodInfo(
			"steps_result",
			PropertyInfo(Variant::INT, "start_unix"),
			PropertyInfo(Variant::INT, "steps")));
	ADD_SIGNAL(MethodInfo("step_error", PropertyInfo(Variant::STRING, "message")));
}

StepCounterPlugin *StepCounterPlugin::get_singleton() {
	return singleton;
}

bool StepCounterPlugin::has_permission() const {
	// HealthKit intentionally does not reveal whether read access was denied. This flag
	// therefore means that the authorization sheet completed successfully at least once.
	return [[NSUserDefaults standardUserDefaults] boolForKey:AUTHORIZATION_COMPLETED_KEY];
}

void StepCounterPlugin::request_permission() {
	if (![HKHealthStore isHealthDataAvailable]) {
		emit_step_error("Health data is not available on this device.");
		emit_permission_result(false);
		return;
	}

	HKQuantityType *step_type = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
	if (step_type == nil) {
		emit_step_error("The HealthKit step-count type is unavailable.");
		emit_permission_result(false);
		return;
	}

	NSSet<HKObjectType *> *read_types = [NSSet setWithObject:step_type];
	[health_store requestAuthorizationToShareTypes:[NSSet set]
										readTypes:read_types
									   completion:^(BOOL success, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			StepCounterPlugin *plugin = StepCounterPlugin::get_singleton();
			if (plugin == nullptr) {
				return;
			}
			if (error != nil) {
				plugin->emit_step_error(godot_string(error.localizedDescription));
				plugin->emit_permission_result(false);
				return;
			}

			// A successful completion means the sheet was handled. Apple deliberately
			// returns the same success value whether read access was allowed or denied.
			[[NSUserDefaults standardUserDefaults] setBool:success forKey:AUTHORIZATION_COMPLETED_KEY];
			plugin->emit_permission_result(success);
		});
	}];
}

void StepCounterPlugin::query_steps_since(int64_t p_start_unix) {
	if (![HKHealthStore isHealthDataAvailable]) {
		emit_step_error("Health data is not available on this device.");
		return;
	}

	HKQuantityType *step_type = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
	if (step_type == nil) {
		emit_step_error("The HealthKit step-count type is unavailable.");
		return;
	}

	const int64_t safe_start_unix = std::max<int64_t>(0, p_start_unix);
	NSDate *start_date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)safe_start_unix];
	NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:start_date
															  endDate:[NSDate date]
															  options:HKQueryOptionStrictStartDate];
	HKStatisticsQuery *query = [[HKStatisticsQuery alloc]
			initWithQuantityType:step_type
			quantitySamplePredicate:predicate
			options:HKStatisticsOptionCumulativeSum
			completionHandler:^(HKStatisticsQuery *query, HKStatistics *statistics, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			StepCounterPlugin *plugin = StepCounterPlugin::get_singleton();
			if (plugin == nullptr) {
				return;
			}
			if (error != nil) {
				plugin->emit_step_error(godot_string(error.localizedDescription));
				return;
			}

			double total = [[statistics sumQuantity] doubleValueForUnit:[HKUnit countUnit]];
			int64_t steps = std::max<int64_t>(0, (int64_t)std::floor(total));
			plugin->emit_steps_result(safe_start_unix, steps);
		});
	}];
	[health_store executeQuery:query];
}

void StepCounterPlugin::emit_permission_result(bool p_granted) {
	emit_signal(SNAME("permission_result"), p_granted);
}

void StepCounterPlugin::emit_steps_result(int64_t p_start_unix, int64_t p_steps) {
	emit_signal(SNAME("steps_result"), p_start_unix, p_steps);
}

void StepCounterPlugin::emit_step_error(const String &p_message) {
	emit_signal(SNAME("step_error"), p_message);
}

StepCounterPlugin::StepCounterPlugin() {
	ERR_FAIL_COND(singleton != nullptr);
	singleton = this;
	health_store = [[HKHealthStore alloc] init];
}

StepCounterPlugin::~StepCounterPlugin() {
	health_store = nil;
	singleton = nullptr;
}
