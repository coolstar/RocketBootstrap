#include <Availability.h>
#undef __IOS_PROHIBITED
#define __IOS_PROHIBITED

#import "log.h"
#include <bootstrap.h>
#ifndef __APPLE_API_PRIVATE
#define __APPLE_API_PRIVATE
#include "sandbox.h"
#undef __APPLE_API_PRIVATE
#else
#include "sandbox.h"
#endif

#import <mach/mach.h>

static BOOL fill_redirected_name(char new_name[BOOTSTRAP_MAX_NAME_LEN], const name_t old_name) {
	size_t length = strlen(old_name);
	if (length > 128 - 8) {
		return NO;
	}
	memcpy(new_name, "lh:rbs:", 7);
	memcpy(new_name + 7, old_name, length + 1);
	return YES;
}

kern_return_t rocketbootstrap_look_up(mach_port_t bp, const name_t service_name, mach_port_t *sp)
{
	#ifdef DEBUG
	NSLog(@"RocketBootstrap: rocketbootstrap_look_up(%llu, %s, %p)", (unsigned long long)bp, service_name, sp);
#endif
	char redirected_name[BOOTSTRAP_MAX_NAME_LEN];
	if (!fill_redirected_name(redirected_name, service_name)) {
		return 1;
	}
	return bootstrap_look_up(bp, redirected_name, sp);
}

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
kern_return_t rocketbootstrap_unlock(const name_t service_name)
{
#ifdef DEBUG
	NSLog(@"RocketBootstrap: rocketbootstrap_unlock(%s)", service_name);
#endif
	char redirected_name[BOOTSTRAP_MAX_NAME_LEN];
	if (!fill_redirected_name(redirected_name, service_name)) {
		return 1;
	}
	mach_port_t bootstrap = MACH_PORT_NULL;
	task_get_bootstrap_port(mach_task_self(), &bootstrap);
	mach_port_t service;
	kern_return_t err = bootstrap_look_up(bootstrap, service_name, &service);
	if (err != 0) {
		// If the current process is permitted to register for this port, assume it's about to
		int sandbox_result = sandbox_check(getpid(), "mach-register", SANDBOX_FILTER_LOCAL_NAME | SANDBOX_CHECK_NO_REPORT, service_name);
		if (sandbox_result) {
			return sandbox_result;
		}
		char *copied_service_name = strdup(service_name);
		CFRunLoopRef runLoop = CFRunLoopGetCurrent();
		CFRunLoopPerformBlock(runLoop, kCFRunLoopCommonModes, ^{
			mach_port_t bootstrap = MACH_PORT_NULL;
			task_get_bootstrap_port(mach_task_self(), &bootstrap);
			mach_port_t service;
			kern_return_t err = bootstrap_look_up(bootstrap, copied_service_name, &service);
			if (err == 0) {
				char redirected_name[BOOTSTRAP_MAX_NAME_LEN];
				fill_redirected_name(redirected_name, copied_service_name);
				err = bootstrap_register(bootstrap, redirected_name, service);
				if (err != 0) {
					mach_port_deallocate(mach_task_self(), service);
				}
			}
			free(copied_service_name);
		});
		CFRunLoopWakeUp(runLoop);
		return 0;
	}
	err = bootstrap_register(bootstrap, redirected_name, service);
	if (err != 0) {
		mach_port_deallocate(mach_task_self(), service);
		return err;
	}
	return 0;
}

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
kern_return_t rocketbootstrap_register(mach_port_t bp, name_t service_name, mach_port_t sp)
{
	char redirected_name[BOOTSTRAP_MAX_NAME_LEN];
	if (!fill_redirected_name(redirected_name, service_name)) {
		return 1;
	}
	return bootstrap_register(bp, redirected_name, sp);
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
